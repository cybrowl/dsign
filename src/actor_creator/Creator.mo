import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Logger "canister:logger";

import Types "./types";
import UUID "../libs/uuid";
import Utils "./utils";
import Arr "../libs/array";

actor class Creator(username_registry : Principal) = this {
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
	type Feedback = Types.Feedback;
	type FavoriteID = Types.FavoriteID;
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
	type Username = Types.Username;
	type UserPrincipal = Types.UserPrincipal;

	//NOTE: This canister will only hold 100 users, each using 20MB each around 2GB
	// Once 100 users is reached it will create another instace of itself.
	// Images and Files will be stored in scalable storage units.
	// TODO: There needs to be an upgrade method that allows a user to move their data to a 4GB canister

	// ------------------------- Variables -------------------------
	let MAX_USERS : Nat = 100;
	// let USERNAME_REGISTRY_ID : Text = Principal.toText(username_registry);
	let VERSION : Nat = 1; // The Version in Production

	var users : Nat = 0;
	var creator_canister_id = "";

	// ------------------------- Storage Data -------------------------
	// profiles
	var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);

	// username to principal ref
	var usernames : HashMap.HashMap<Username, UserPrincipal> = HashMap.HashMap(
		0,
		Text.equal,
		Text.hash
	);

	// favorites (only lives within profile)
	// NOTE: the data is cached, cron job runs every N time
	// var favorites : HashMap.HashMap<FavoriteID, Project> = HashMap.HashMap(
	//     0,
	//     Text.equal,
	//     Text.hash
	// );

	// projects
	var projects : HashMap.HashMap<ProjectID, Project> = HashMap.HashMap(0, Text.equal, Text.hash);

	// snaps
	var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);

	// ------------------------- Profile -------------------------
	// Get Number Of Users
	public query func total_users() : async Nat {
		return profiles.size();
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

		if (users > MAX_USERS) {
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

						//NOTE: for now all files are deleted in UI but that can be done in separate canister that has authority within FS to delete
						//TODO: delete all the snaps from the project
						//TODO: delete all the assets from snaps

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

	// Create Feedback Topic
	// TODO: skip until I fix everthing we have in UI
	// NOTE: this is called from `snap_view`, and redirects them to `feedback` with topic selected
	// Inside the Creator actor class

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

				// Create A Topic
				let topic : Topic = {
					id = args.snap_id;
					snap_name = "";
					design_file = null;
					messages = [{
						created = Time.now();
						content = "Give feedback, ask a question, or just leave a note.";
						username = "Jinx-Bot";
					}];
				};

				let feedback_udapted : Feedback = {
					topics = ?[topic];
				};

				let project_updated : Project = {
					project with
					feedback = feedback_udapted;
				};

				return #ok(topic);
			};
		};
	};

	public shared ({}) func add_message_to_topic(args : ArgsUpdateTopic) : async Result.Result<Text, Text> {
		//TODO: this should create a new message into the topic from this user
		return #ok("");
	};

	public shared ({}) func add_file_to_topic(args : ArgsUpdateTopic) : async Result.Result<Text, Text> {
		//TODO: add design_file to topic
		return #ok("");
	};

	public shared ({}) func remove_file_from_topic(args : ArgsUpdateTopic) : async Result.Result<Text, Text> {
		//TODO: this should delete the design_file from the topic
		return #ok("");
	};

	public shared ({}) func update_snap_with_file_change(args : ArgsUpdateTopic) : async Result.Result<Text, Text> {
		//TODO: this is probably a bit more complicated and I need to think about
		//TODO: the file will be owned by the user that uploaded it
		// it will need to change onwers
		// M-O needs to have access to not only delete files but alse change owners
		return #ok("");
	};

	public shared ({}) func delete_feedback_topic(id : ProjectID) : async Result.Result<Text, Text> {
		// TODO: needs to delete the feedback topic from the project

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

						return #ok(snap_public);
					};
				};
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

				// Update the snap with the filtered images list
				let updated_snap = {
					snap with
					images = remaining_images;
				};

				// Update the snap in the hashmap
				snaps.put(snap_id, updated_snap);

				return #ok(true);
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
						};
					};
				};
			};
		};

		return #ok(true);
	};

	// Delete Snap Images
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

				let snap_updated = {
					snap with
					design_file = null;
				};

				snaps.put(id, snap_updated);

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

	public shared func init() : async () {
		creator_canister_id := Principal.toText(Principal.fromActor(this));

		return ();
	};

	// Get CanisterId
	public query func get_canister_id() : async Text {
		return creator_canister_id;
	};

	// Post Upgrade
	system func postupgrade() {};
};
