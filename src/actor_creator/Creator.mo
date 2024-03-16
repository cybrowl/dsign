import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Explore "canister:explore";
import Logger "canister:logger";
import MO "canister:mo";

import Types "./types";
import UsernameRegistryTypes "../actor_username_registry/types";

import UUID "../libs/uuid";
import Utils "./utils";
import Arr "../libs/array";

actor class Creator(username_registry : Principal) = self {
	type ArgsCreateProject = Types.ArgsCreateProject;
	type ArgsCreateSnap = Types.ArgsCreateSnap;
	type ArgsCreateTopic = Types.ArgsCreateTopic;
	type ArgsUpdateProfile = Types.ArgsUpdateProfile;
	type ArgsUpdateProject = Types.ArgsUpdateProject;
	type ArgsUpdateSnap = Types.ArgsUpdateSnap;
	type ArgsUpdateTopic = Types.ArgsUpdateTopic;
	type ErrProfile = Types.ErrProfile;
	type ErrProject = Types.ErrProject;
	type ErrSnap = Types.ErrSnap;
	type ErrTopic = Types.ErrTopic;
	type FavoriteID = Types.FavoriteID;
	type Feedback = Types.Feedback;
	type FileAsset = Types.FileAsset;
	type FileAssetID = Types.FileAssetID;
	type Profile = Types.Profile;
	type ProfilePublic = Types.ProfilePublic;
	type Project = Types.Project;
	type ProjectID = Types.ProjectID;
	type ProjectPublic = Types.ProjectPublic;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;
	type Topic = Types.Topic;
	type TopicMessage = Types.TopicMessage;
	type Username = Types.Username;
	type UserPrincipal = Types.UserPrincipal;

	type UsernameRegistryActor = UsernameRegistryTypes.UsernameRegistryActor;

	//NOTE: This canister will only hold 100 users, each using 20MB each around 2GB
	// Once 100 users is reached it will create another instace of itself.
	// Images and Files will be stored in scalable storage units.
	// TODO: There needs to be an upgrade method that allows a user to move their data to a 4GB canister

	// ------------------------- Variables -------------------------
	let MAX_USERS : Nat = 100;
	let VERSION : Nat = 2; // The Version in Production

	stable var creator_canister_id = "";

	// ------------------------- Storage Data -------------------------
	// profiles
	var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var profiles_stable_storage : [(UserPrincipal, Profile)] = [];

	// username to principal ref
	var usernames : HashMap.HashMap<Username, UserPrincipal> = HashMap.HashMap(
		0,
		Text.equal,
		Text.hash
	);
	stable var usernames_stable_storage : [(Username, UserPrincipal)] = [];

	// favorites (only lives within profile)
	// NOTE: the data is cached, cron job runs every N time
	// var favorites : HashMap.HashMap<FavoriteID, Project> = HashMap.HashMap(
	//     0,
	//     Text.equal,
	//     Text.hash
	// );

	// projects
	var projects : HashMap.HashMap<ProjectID, Project> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var projects_stable_storage : [(ProjectID, Project)] = [];

	// snaps
	var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var snaps_stable_storage : [(SnapID, Snap)] = [];

	// ------------------------- Profile -------------------------
	// Get Number Of Profiles
	public query func total_profiles() : async Nat {
		return profiles.size();
	};

	// Get Number Of Usernames
	public query func total_usernames() : async Nat {
		return usernames.size();
	};

	// Get Profile by Username
	public query ({ caller }) func get_profile_by_username(username : Username) : async Result.Result<ProfilePublic, ErrProfile> {
		switch (usernames.get(username)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?creator_principal) {
				switch (profiles.get(creator_principal)) {
					case (null) {
						return #err(#ProfileNotFound(true));
					};
					case (?profile) {
						let projects_public = Utils.projects_to_public(profile.projects, projects, snaps, caller);

						let favorites_public : [Project] = Array.mapFilter<FavoriteID, Project>(
							profile.favorites,
							func(id : FavoriteID) : ?Project {
								switch (projects.get(id)) {
									case (null) {
										return null;
									};
									case (?project) {
										return ?project;
									};
								};
							}
						);

						return #ok({
							avatar = profile.avatar;
							banner = profile.banner;
							created = profile.created;
							canister_id = creator_canister_id;
							username = profile.username;
							is_owner = Principal.equal(caller, profile.owner);
							projects = projects_public;
							favorites = favorites_public;
							storage_metrics = profile.storage_metrics;
						});
					};
				};
			};
		};
	};

	// Create Profile
	public shared ({ caller }) func create_profile(username : Username, owner : UserPrincipal) : async Result.Result<Username, ErrProfile> {
		let tags = [("canister_id", creator_canister_id), ("method", "create_profile")];

		if (Principal.equal(caller, username_registry) == false) {
			return #err(#NotAuthorizedCaller);
		};

		if (usernames.size() > MAX_USERS) {
			return #err(#MaxUsersExceeded);
		};

		let profile : Profile = {
			avatar = {
				id = "";
				canister_id = "";
				url = "";
			};
			banner = {
				id = "";
				canister_id = "";
				url = "/default_profile_banner.png";
			};
			created = Time.now();
			canister_id = creator_canister_id;
			username = username;
			owner = owner;
			favorites = [];
			projects = [];
			storage_metrics = null;
		};

		profiles.put(owner, profile);
		usernames.put(username, owner);

		ignore Logger.log_event(tags, "profile_created");

		return #ok(username);
	};

	// Update Profile Avatar
	public shared ({ caller }) func update_profile_avatar(args : ArgsUpdateProfile) : async Result.Result<Text, ErrProfile> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};

			case (?profile) {
				let avatar_delete : FileAsset = {
					id = profile.avatar.id;
					canister_id = profile.avatar.canister_id;
					chunks_size = 1;
					content_encoding = #Identity;
					content_size = 1;
					content_type = "image";
					created = 1;
					name = "NA";
					url = profile.avatar.url;
				};

				let avatar_updated = {
					id = args.id;
					canister_id = args.canister_id;
					url = args.url;
				};

				let profile_updated = {
					profile with
					avatar = avatar_updated;
				};

				profiles.put(caller, profile_updated);

				ignore MO.delete_files([avatar_delete]);

				return #ok(profile_updated.avatar.url);
			};
		};
	};

	// Update Profile Banner
	public shared ({ caller }) func update_profile_banner(args : ArgsUpdateProfile) : async Result.Result<Text, ErrProfile> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};

			case (?profile) {
				let banner_delete : FileAsset = {
					id = profile.banner.id;
					canister_id = profile.banner.canister_id;
					chunks_size = 1;
					content_encoding = #Identity;
					content_size = 1;
					content_type = "image";
					created = 1;
					name = "NA";
					url = profile.banner.url;
				};

				let banner_updated = {
					id = args.id;
					canister_id = args.canister_id;
					url = args.url;
				};

				let profile_updated = {
					profile with
					banner = banner_updated;
				};

				profiles.put(caller, profile_updated);

				ignore MO.delete_files([banner_delete]);

				return #ok(profile_updated.banner.url);
			};
		};
	};

	// ------------------------- Projects -------------------------
	// Get Number of Projects
	public query func total_projects() : async Nat {
		return projects.size();
	};

	// Get Project
	public query ({ caller }) func get_project(id : ProjectID) : async Result.Result<ProjectPublic, ErrProject> {
		switch (projects.get(id)) {
			case (null) {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				let project_public = Utils.project_to_public(project, snaps, caller);

				return #ok(project_public);
			};
		};
	};

	// Create Project
	public shared ({ caller }) func create_project(args : ArgsCreateProject) : async Result.Result<ProjectPublic, ErrProject> {
		//TODO: sanitize the args

		let id : ProjectID = await UUID.generate();

		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {

				// Add Project
				let project : Project = {
					id = id;
					canister_id = creator_canister_id;
					created = Time.now();
					name = args.name;
					description = args.description;
					username = profile.username;
					owner = caller;
					snaps = [];
					feedback = {
						topics = null;
					};
					metrics = {
						likes = 0;
						views = 0;
					};
				};

				projects.put(id, project);

				// Add Project to Profile
				let profile_projects : Buffer.Buffer<ProjectID> = Buffer.fromArray(profile.projects);
				profile_projects.add(id);

				let profile_updated : Profile = {
					profile with
					projects = Buffer.toArray(profile_projects);
				};

				profiles.put(caller, profile_updated);

				let snaps_public : [SnapPublic] = [];

				let project_public : ProjectPublic = {
					project with
					is_owner = true;
					owner = null;
					snaps = snaps_public;
				};

				return #ok(project_public);
			};
		};
	};

	// Update Project
	public shared ({ caller }) func update_project(args : ArgsUpdateProject) : async Result.Result<ProjectPublic, ErrProject> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {
				switch (projects.get(args.id)) {
					case (null) {
						return #err(#ProjectNotFound(true));
					};
					case (?project) {
						if (Principal.notEqual(project.owner, caller)) {
							return #err(#NotOwner(true));
						};

						let description : Text = switch (args.description) {
							case (null) { Option.get(project.description, "") };
							case (?description) { description };
						};

						let project_updated : Project = {
							project with
							name = Option.get(args.name, project.name);
							description = ?description;
						};

						projects.put(args.id, project_updated);

						let project_public = Utils.project_to_public(project_updated, snaps, caller);

						if (project_updated.snaps.size() > 0) {
							ignore Explore.update_project(project.id, project.canister_id);
						};

						return #ok(project_public);
					};
				};
			};
		};
	};

	// Delete Project
	public shared ({ caller }) func delete_project(id : ProjectID) : async Result.Result<Bool, ErrProject> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {
				switch (projects.get(id)) {
					case (null) {
						return #err(#ProjectNotFound(true));
					};
					case (?project) {
						if (Principal.notEqual(project.owner, caller)) {
							return #err(#NotOwner(true));
						};

						let profile_projects : Buffer.Buffer<ProjectID> = Buffer.fromArray(profile.projects);

						// Filter out the project ID to be deleted
						profile_projects.filterEntries(
							func(idx : Nat, projId : ProjectID) : Bool {
								return projId != id;
							}
						);

						// Delete files
						let file_assets : [FileAsset] = Utils.get_file_assets_from_project(project, snaps);
						ignore MO.delete_files(file_assets);

						ignore Explore.delete_projects([id]);

						//TODO: should it delete for Favorites too since the owner deleted the files?

						projects.delete(id);

						let profile_updated : Profile = {
							profile with
							projects = Buffer.toArray(profile_projects);
						};

						profiles.put(caller, profile_updated);

						return #ok(true);
					};
				};
			};
		};
	};

	// ------------------------- Projects / Feedback -------------------------
	// Create Feedback Topic
	public shared func create_feedback_topic(args : ArgsCreateTopic) : async Result.Result<Topic, ErrTopic> {
		switch (projects.get(args.project_id)) {
			case (null) {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {

				let topics : [Topic] = switch (project.feedback.topics) {
					case (null) { [] };
					case (?topics) { topics };
				};

				let topic_exists = Arr.exists<Topic>(
					topics,
					func(topic) : Bool {
						topic.id == args.snap_id;
					}
				);

				if (topic_exists) {
					return #err(#TopicExists(true));
				};

				let snap_name : Text = switch (snaps.get(args.snap_id)) {
					case (null) { "" };
					case (?snap) { snap.name };
				};

				let default_topic : Topic = {
					id = args.snap_id;
					snap_name = snap_name;
					design_file = null;
					messages = [{
						created = Time.now();
						content = "Give feedback, ask a question, or just leave a note.";
						username = "Jinx-Bot";
					}];
				};

				let all_topics = Arr.append([default_topic], topics);

				var feedback_udapted : Feedback = {
					topics = ?all_topics;
				};

				let project_updated : Project = {
					project with
					feedback = feedback_udapted;
				};

				projects.put(project.id, project_updated);

				return #ok(default_topic);
			};
		};
	};

	// Add Message to Topic
	public shared ({ caller }) func add_message_to_topic(args : ArgsUpdateTopic) : async Result.Result<Topic, ErrTopic> {
		switch (projects.get(args.project_id)) {
			case (null) {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				let topics : [Topic] = switch (project.feedback.topics) {
					case (null) { [] };
					case (?topics) { topics };
				};

				let topic_found : ?Topic = Array.find<Topic>(
					topics,
					func(t) : Bool { t.id == args.snap_id }
				);

				switch (topic_found) {
					case (null) {
						return #err(#TopicNotFound(true));
					};
					case (?topic) {
						let username_registry_actor : UsernameRegistryActor = actor (Principal.toText(username_registry));

						var username = "";
						switch (await username_registry_actor.get_username_by_principal(caller)) {
							case (#err err) {
								return #err(#UsernameNotFound(true));
							};
							case (#ok username_) {
								username := username_;
							};
						};

						let new_message : TopicMessage = {
							created = Time.now();
							content = Option.get(args.message, "");
							username = username;
						};

						let messages_udpated = Arr.append<TopicMessage>(topic.messages, [new_message]);

						let topic_updated = {
							topic with messages = messages_udpated;
						};

						let topic_index : ?Nat = Arr.findIndex<Topic>(
							topics,
							func(t) : Bool { t.id == args.snap_id }
						);

						let topics_updated = Arr.replace<Topic>(topics, Option.get(topic_index, 0), topic_updated);

						let feedback_updated : Feedback = { topics = ?topics_updated };
						let project_updated : Project = { project with feedback = feedback_updated };

						projects.put(project.id, project_updated);

						return #ok(topic_updated);
					};
				};
			};
		};
	};

	// Add File to Topic
	public shared func add_file_to_topic(args : ArgsUpdateTopic) : async Result.Result<Topic, ErrTopic> {
		//TODO: make sure the caller owns the file that it wants to commit
		//TODO: make sure the file is from the caller that opened the topic

		switch (projects.get(args.project_id)) {
			case (null) {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				let topics : [Topic] = switch (project.feedback.topics) {
					case (null) { [] };
					case (?topics) { topics };
				};

				let topic_found : ?Topic = Array.find<Topic>(
					topics,
					func(t) : Bool { t.id == args.snap_id }
				);

				switch (topic_found) {
					case (null) {
						return #err(#TopicNotFound(true));
					};
					case (?topic) {
						switch (topic.design_file) {
							case (null) {
								let topic_updated = {
									topic with design_file = args.design_file;
								};

								let topic_index : ?Nat = Arr.findIndex<Topic>(
									topics,
									func(t) : Bool { t.id == args.snap_id }
								);

								let topics_updated = Arr.replace<Topic>(topics, Option.get(topic_index, 0), topic_updated);

								let feedback_updated : Feedback = { topics = ?topics_updated };
								let project_updated : Project = {
									project with feedback = feedback_updated
								};

								projects.put(project.id, project_updated);

								return #ok(topic_updated);

							};
							case (?design_file) {
								return #err(#DesignFileExists(true));
							};
						};
					};
				};
			};
		};
	};

	// Remove File from Topic [Owner]
	public shared ({ caller }) func delete_file_from_topic(args : ArgsUpdateTopic) : async Result.Result<Topic, ErrTopic> {
		switch (projects.get(args.project_id)) {
			case (null) {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				if (Principal.notEqual(project.owner, caller)) {
					return #err(#NotOwner(true));
				};

				let topics : [Topic] = switch (project.feedback.topics) {
					case (null) { [] };
					case (?topics) { topics };
				};

				let topic_found : ?Topic = Array.find<Topic>(
					topics,
					func(t) : Bool { t.id == args.snap_id }
				);

				switch (topic_found) {
					case (null) {
						return #err(#TopicNotFound(true));
					};
					case (?topic) {
						switch (topic.design_file) {
							case (null) {
								return #err(#DesignFileExists(true));
							};
							case (?design_file) {
								let topic_updated = {
									topic with design_file = null;
								};

								let topic_index : ?Nat = Arr.findIndex<Topic>(
									topics,
									func(t) : Bool { t.id == args.snap_id }
								);

								let topics_updated = Arr.replace<Topic>(topics, Option.get(topic_index, 0), topic_updated);

								let feedback_updated : Feedback = { topics = ?topics_updated };
								let project_updated : Project = {
									project with feedback = feedback_updated
								};

								projects.put(project.id, project_updated);

								ignore MO.delete_files([design_file]);

								return #ok(topic_updated);
							};
						};
					};
				};
			};
		};
	};

	// Delete Feedback Topic [Owner]
	public shared ({ caller }) func delete_feedback_topic(args : ArgsUpdateTopic) : async Result.Result<Bool, ErrTopic> {
		switch (projects.get(args.project_id)) {
			case (null) {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				if (Principal.notEqual(project.owner, caller)) {
					return #err(#NotOwner(true));
				};

				let topics : [Topic] = switch (project.feedback.topics) {
					case (null) { [] };
					case (?topics) { topics };
				};

				let topic_found : ?Topic = Array.find<Topic>(
					topics,
					func(t) : Bool { t.id == args.snap_id }
				);

				switch (topic_found) {
					case (null) {
						return #err(#TopicNotFound(true));
					};
					case (?topic) {
						let topics_updated = Array.filter<Topic>(
							topics,
							func(t : Topic) : Bool {
								return t.id != args.snap_id;
							}
						);

						let feedback_updated : Feedback = { topics = ?topics_updated };
						let project_updated : Project = {
							project with feedback = feedback_updated
						};

						projects.put(project.id, project_updated);

						let file_assets : [FileAsset] = Utils.get_file_assets_from_topic(topic);
						ignore MO.delete_files(file_assets);

						return #ok(true);
					};
				};
			};
		};
	};

	// Update Snap with new File Change [Owner]
	public shared ({}) func update_snap_with_file_change(args : ArgsUpdateTopic) : async Result.Result<Text, Text> {
		//TODO: this is probably a bit more complicated and I need to think about
		//TODO: the file will be owned by the user that uploaded it
		// it will need to change onwers
		// M-O needs to have access to not only delete files but alse change owners
		return #ok("");
	};

	// ------------------------- Snaps -------------------------
	// Get Snap
	public query ({ caller }) func get_snap(id : SnapID) : async Result.Result<SnapPublic, ErrSnap> {
		switch (snaps.get(id)) {
			case (null) {
				return #err(#SnapNotFound(true));
			};
			case (?snap) {
				//TODO: add project_name as part of the snap public

				let snap_public : SnapPublic = {
					snap with
					owner = null;
					is_owner = Principal.equal(caller, snap.owner);
				};

				return #ok(snap_public);
			};
		};
	};

	// Create Snap
	public shared ({ caller }) func create_snap(args : ArgsCreateSnap) : async Result.Result<SnapPublic, ErrSnap> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {
				switch (projects.get(args.project_id)) {
					case (null) {
						return #err(#ProjectNotFound(true));
					};
					case (?project) {
						if (Principal.notEqual(project.owner, caller)) {
							return #err(#NotOwner(true));
						};

						let id : SnapID = await UUID.generate();

						let snap : Snap = {
							id = id;
							project_id = args.project_id;
							canister_id = creator_canister_id;
							created = Time.now();
							updated = Time.now();
							name = args.name;
							tags = Option.get(args.tags, []);
							username = profile.username;
							owner = caller;
							design_file = args.design_file;
							images = args.images;
							image_cover_location = args.image_cover_location;
							metrics = {
								likes = 0;
								views = 0;
							};
						};

						snaps.put(id, snap);

						// Add Snap to Project
						let project_snaps : Buffer.Buffer<SnapID> = Buffer.fromArray(project.snaps);
						project_snaps.add(id);

						let project_updated : Project = {
							project with
							snaps = Buffer.toArray(project_snaps);
						};

						projects.put(args.project_id, project_updated);

						let snap_public : SnapPublic = {
							snap with
							owner = null;
							is_owner = true;
						};

						ignore Explore.update_project(project.id, project.canister_id);

						return #ok(snap_public);
					};
				};
			};
		};
	};

	// Update Snap
	public shared ({ caller }) func update_snap(args : ArgsUpdateSnap) : async Result.Result<SnapPublic, ErrSnap> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {
				switch (snaps.get(args.id)) {
					case (null) {
						return #err(#ProjectNotFound(true));
					};
					case (?snap) {
						if (Principal.notEqual(snap.owner, caller)) {
							return #err(#NotOwner(true));
						};

						// Update the optional fields only if they are provided
						let updated_tags = switch (args.tags) {
							case (null) { snap.tags };
							case (?tags) { tags };
						};

						let updated_design_file = switch (args.design_file) {
							case (null) { snap.design_file };
							case (?design_file) { ?design_file };
						};

						let updated_image_cover_location = switch (args.image_cover_location) {
							case (null) { snap.image_cover_location };
							case (?location) { location };
						};

						// Update snap
						let updated_snap : Snap = {
							id = snap.id;
							project_id = snap.project_id;
							canister_id = snap.canister_id;
							created = snap.created;
							updated = Time.now();
							name = Option.get(args.name, snap.name);
							tags = updated_tags;
							username = snap.username;
							owner = snap.owner;
							design_file = updated_design_file;
							image_cover_location = updated_image_cover_location;
							images = snap.images;
							metrics = snap.metrics;
						};

						snaps.put(snap.id, updated_snap);

						let snap_public : SnapPublic = {
							updated_snap with
							owner = ?caller;
							is_owner = true;
						};

						ignore Explore.update_project(snap.project_id, snap.canister_id);

						return #ok(snap_public);
					};
				};
			};
		};
	};

	// Add Images
	public shared ({ caller }) func add_images_to_snap(snap_id : SnapID, new_images : [FileAsset]) : async Result.Result<Bool, ErrSnap> {
		switch (snaps.get(snap_id)) {
			case (null) {
				return #err(#SnapNotFound(true));
			};
			case (?snap) {
				if (Principal.notEqual(snap.owner, caller)) {
					return #err(#NotOwner(true));
				};

				let updated_images = Arr.append<FileAsset>(snap.images, new_images);

				let updated_snap = {
					snap with
					images = updated_images;
				};

				snaps.put(snap_id, updated_snap);

				ignore Explore.update_project(snap.project_id, snap.canister_id);

				return #ok(true);
			};
		};
	};

	// Delete Image
	public shared ({ caller }) func delete_image_from_snap(snap_id : SnapID, image_id : FileAssetID) : async Result.Result<Bool, ErrSnap> {
		switch (snaps.get(snap_id)) {
			case (null) {
				return #err(#SnapNotFound(true));
			};
			case (?snap) {
				if (Principal.notEqual(snap.owner, caller)) {
					return #err(#NotOwner(true));
				};

				// Filter out the image with the given FileAssetID
				let remaining_images = Array.filter<FileAsset>(
					snap.images,
					func(image : FileAsset) : Bool {
						image.id != image_id;
					}
				);

				let image_to_delete = Array.filter<FileAsset>(
					snap.images,
					func(image : FileAsset) : Bool {
						image.id == image_id;
					}
				);

				// Update the snap with the filtered images list
				let updated_snap = {
					snap with
					images = remaining_images;
				};

				// Update the snap in the hashmap
				snaps.put(snap_id, updated_snap);

				ignore Explore.update_project(snap.project_id, snap.canister_id);

				ignore MO.delete_files(image_to_delete);

				return #ok(true);
			};
		};
	};

	// Delete Snaps
	public shared ({ caller }) func delete_snaps(ids : [SnapID]) : async Result.Result<Bool, ErrSnap> {
		for (id in ids.vals()) {
			switch (snaps.get(id)) {
				case (null) {
					return #err(#SnapNotFound(true));
				};
				case (?snap) {
					if (Principal.notEqual(snap.owner, caller)) {
						return #err(#NotOwner(true));
					};

					// Proceed to delete the snap
					snaps.delete(id);

					switch (projects.get(snap.project_id)) {
						case (null) {
							return #err(#ProfileNotFound(true));
						};
						case (?project) {
							// Filter out the deleted snap ID from the project's snaps array
							let snaps_updated = Array.filter<SnapID>(project.snaps, func(s) { s != id });
							let project_updated = {
								project with
								snaps = snaps_updated;
							};

							projects.put(snap.project_id, project_updated);

							ignore Explore.update_project(snap.project_id, snap.canister_id);

							let file_assets = Utils.get_file_assets_from_snap(snap);
							ignore MO.delete_files(file_assets);
						};
					};
				};
			};
		};

		return #ok(true);
	};

	// Delete Snap Images
	// NOTE: this isn't being USED?
	public shared ({ caller }) func delete_snap_images(snap_id : SnapID, ids : [FileAssetID]) : async Result.Result<Bool, ErrSnap> {
		switch (snaps.get(snap_id)) {
			case (null) {
				return #err(#SnapNotFound(true));
			};
			case (?snap) {
				if (Principal.notEqual(snap.owner, caller)) {
					return #err(#NotOwner(true));
				};

				let remaining_images = Array.filter<FileAsset>(
					snap.images,
					func(image : FileAsset) : Bool {
						var is_not_in_ids = true;

						for (id in ids.vals()) {
							if (id == image.id) {
								is_not_in_ids := false;
							};
						};

						is_not_in_ids;
					}
				);

				let snap_updated = {
					snap with
					images = remaining_images;
				};

				snaps.put(snap_id, snap_updated);

				ignore Explore.update_project(snap.project_id, snap.canister_id);

				return #ok(true);
			};
		};
	};

	// Delete Snap Design File
	public shared ({ caller }) func delete_snap_design_file(id : SnapID) : async Result.Result<Bool, ErrSnap> {
		switch (snaps.get(id)) {
			case (null) {
				return #err(#SnapNotFound(true));
			};
			case (?snap) {
				if (Principal.notEqual(snap.owner, caller)) {
					return #err(#NotOwner(true));
				};

				let design_file_deletion : [FileAsset] = switch (snap.design_file) {
					case (null) { [] };
					case (?file) { [file] };
				};

				let snap_updated = {
					snap with
					design_file = null;
				};

				snaps.put(id, snap_updated);

				ignore MO.delete_files(design_file_deletion);

				return #ok(true);
			};
		};
	};

	// ------------------------- Favorites -------------------------
	// Get Number of Favorites
	// public query func total_favorites() : async Nat {
	//     return favorites.size();
	// };

	// Save Project as Favorite
	public shared ({ caller }) func save_project_as_fav(project_id : ProjectID) : async Result.Result<Bool, ErrProfile> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {
				if (projects.get(project_id) == null) {
					return #err(#ProfileNotFound(true));
				};

				if (Array.find<FavoriteID>(profile.favorites, func(id) { id == project_id }) != null) {
					return #ok(false);
				} else {

					let favorites_updated = Arr.append<FavoriteID>(profile.favorites, [project_id]);
					let profile_updated = {
						profile with
						favorites = favorites_updated
					};

					profiles.put(caller, profile_updated);

					return #ok(true);
				};
			};
		};
	};

	// Delete Project from Favorites
	public shared ({ caller }) func delete_project_from_favs(project_id : ProjectID) : async Result.Result<Bool, ErrProfile> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {
				if (Array.find<FavoriteID>(profile.favorites, func(id) { id == project_id }) == null) {
					return #err(#ProfileNotFound(true));
				} else {
					let favorites_updated = Array.filter<FavoriteID>(
						profile.favorites,
						func(id) { id != project_id }
					);

					let profile_updated = {
						profile with
						favorites = favorites_updated
					};

					profiles.put(caller, profile_updated);

					return #ok(true);
				};
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	// Get Version
	public query func version() : async Nat {
		return VERSION;
	};

	// Init
	public shared func init() : async () {
		creator_canister_id := Principal.toText(Principal.fromActor(self));

		return ();
	};

	// Get CanisterId
	public query func get_canister_id() : async Text {
		return creator_canister_id;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		profiles_stable_storage := Iter.toArray(profiles.entries());
		usernames_stable_storage := Iter.toArray(usernames.entries());
		projects_stable_storage := Iter.toArray(projects.entries());
		snaps_stable_storage := Iter.toArray(snaps.entries());

	};

	system func postupgrade() {
		profiles := HashMap.fromIter<UserPrincipal, Profile>(
			profiles_stable_storage.vals(),
			0,
			Principal.equal,
			Principal.hash
		);
		profiles_stable_storage := [];

		usernames := HashMap.fromIter<Username, UserPrincipal>(
			usernames_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		usernames_stable_storage := [];

		projects := HashMap.fromIter<ProjectID, Project>(
			projects_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		projects_stable_storage := [];

		snaps := HashMap.fromIter<SnapID, Snap>(
			snaps_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		snaps_stable_storage := [];
	};
};
