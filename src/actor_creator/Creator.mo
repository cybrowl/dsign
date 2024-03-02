import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Time "mo:base/Time";

import Logger "canister:logger";

import Types "./types";
import UUID "../libs/uuid";

actor class Creator(username_registry : Principal) = this {
	type ArgsCreateProject = Types.ArgsCreateProject;
	type ArgsUpdateProfile = Types.ArgsUpdateProfile;
	type ArgsUpdateProject = Types.ArgsUpdateProject;
	type ErrProfile = Types.ErrProfile;
	type ErrProject = Types.ErrProject;
	type ErrSnap = Types.ErrSnap;
	type FavoriteID = Types.FavoriteID;
	type Profile = Types.Profile;
	type ProfilePublic = Types.ProfilePublic;
	type Project = Types.Project;
	type ProjectID = Types.ProjectID;
	type ProjectPublic = Types.ProjectPublic;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;
	type Username = Types.Username;
	type UserPrincipal = Types.UserPrincipal;

	//NOTE: This canister will only hold 100 users, each using 20MB each around 2GB
	// Once 100 users is reached it will create another instace of itself.
	// Images and Files will be stored in scalable storage units.
	// TODO: There needs to be an upgrade method that allows a user to move their data to a 4GB canister

	// ------------------------- Variables -------------------------
	let VERSION : Nat = 1; // The Version in Production
	let USERNAME_REGISTRY_ID : Text = Principal.toText(username_registry);
	let MAX_USERS : Nat = 100;

	var users : Nat = 0;
	var canister_id : Text = "";

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
	var favorites : HashMap.HashMap<FavoriteID, Project> = HashMap.HashMap(
		0,
		Text.equal,
		Text.hash
	);

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

						let projects_public : [Project] = Array.mapFilter<ProjectID, Project>(
							profile.projects,
							func(id : ProjectID) : ?Project {
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
		let tags = [("canister_id", canister_id), ("method", "create_profile")];

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
	public query func get_project(id : ProjectID) : async Result.Result<ProjectPublic, ErrProject> {
		switch (projects.get(id)) {
			case (null) {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				let project_public : ProjectPublic = {
					project with
					owner = null;
				};

				return #ok(project_public);
			};
		};
	};

	// Create Project
	public shared ({ caller }) func create_project(args : ArgsCreateProject) : async Result.Result<ProjectPublic, ErrProject> {
		//TODO: sanitize the args

		let id : ProjectID = UUID.generate();

		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {

				// Add Project
				let project : Project = {
					id = id;
					canister_id = Principal.toText(Principal.fromActor(this));
					created = Time.now();
					name = args.name;
					description = args.description;
					username = profile.username;
					owner = caller;
					snaps = [];
					feedback = null;
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

				let project_public : ProjectPublic = {
					project with
					owner = null;
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

						let project_public : ProjectPublic = {
							project_updated with
							owner = null;
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
	public shared ({ caller }) func create_feedback_topic() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// ------------------------- Snaps -------------------------
	// Get Snap
	public query func get_snap(id : SnapID) : async Result.Result<SnapPublic, ErrSnap> {
		switch (snaps.get(id)) {
			case (null) {
				return #err(#SnapNotFound(true));
			};
			case (?snap) {
				let snap_public : SnapPublic = {
					snap with
					owner = null;
				};

				return #ok(snap_public);
			};
		};
	};

	// Create Snap
	public shared ({ caller }) func create_snap() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Update Snap
	public shared ({ caller }) func update_snap() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Delete Snaps
	public shared ({ caller }) func delete_snaps(ids : [SnapID]) : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Delete Snap Images
	public shared ({ caller }) func delete_snap_images() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Delete Snap Design File
	public shared ({ caller }) func delete_snap_design_file() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// ------------------------- Favorites -------------------------
	// Get Number of Favorites
	public query func total_favorites() : async Nat {
		return favorites.size();
	};

	// Save Project as Favorite
	public shared ({ caller }) func save_project_as_fav() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Delete Project from Favorites
	public shared ({ caller }) func delete_project_from_favs() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// ------------------------- Canister Management -------------------------
	// Get Version
	public query func version() : async Nat {
		return VERSION;
	};

	// Get CanisterId
	public query func get_canister_id() : async Text {
		return Principal.toText(Principal.fromActor(this));
	};

	// Post Upgrade
	system func postupgrade() {};
};
