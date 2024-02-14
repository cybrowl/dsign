import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Logger "canister:logger";

import Types "./types";

actor class Creator(username_registry : Principal) = this {
	type ErrProfile = Types.ErrProfile;
	type FavoriteID = Types.FavoriteID;
	type Profile = Types.Profile;
	type Project = Types.Project;
	type ProjectID = Types.ProjectID;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type Username = Types.Username;
	type UserPrincipal = Types.UserPrincipal;

	//NOTE: This canister will only hold 100 users, each using 20MB each around 2GB
	// Once 100 users is reached it will create another instace of itself.
	// Images and Files will be stored in scalable storage units.

	// ------------------------- Variables -------------------------
	let VERSION : Nat = 1; // The Version in Production
	let USERNAME_REGISTRY_ID : Text = Principal.toText(username_registry);
	let MAX_USERS : Nat = 100;

	stable var users : Nat = 0;
	stable var canister_id : Text = "";

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

	// Get Profile by User Principal
	public query ({ caller }) func get_profile() : async Result.Result<Profile, ErrProfile> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound(true));
			};
			case (?profile) {
				return #ok(profile);
			};
		};
	};

	// Get Profile by Username
	public query func get_profile_by_username(username : Username) : async Result.Result<Profile, ErrProfile> {
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
						return #ok(profile);
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
				exists = false;
			};
			banner = {
				id = "";
				canister_id = "";
				url = "/default_profile_banner.png";
				exists = false;
			};
			created = Time.now();
			username = username;
			favorites = [];
			projects = [];
			storage = null;
		};

		profiles.put(owner, profile);
		usernames.put(username, owner);

		ignore Logger.log_event(tags, "profile_created");

		return #ok(username);
	};

	// TODO: WARNING
	// Assets need to be handled, it is needed for avatars, banners, snaps (images and files)
	// E2E integration is important with the UI, who knows what lurks in the unknown.
	// Test profile creation & rendering before moving forward.

	// Update Profile Avatar
	public shared ({ caller }) func update_profile_avatar(username : Username) : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Update Profile Banner
	public shared ({ caller }) func update_profile_banner(username : Username) : async Result.Result<Text, Text> {
		return #ok("");
	};

	// ------------------------- Projects -------------------------
	// Get Number of Projects
	public query func total_projects() : async Nat {
		return projects.size();
	};

	// Get Project Owner Status
	public query func get_project_owner_status() : async Text {
		return "";
	};

	// Get Project Metrics
	public query func get_project_metrics() : async Text {
		return "";
	};

	// Get Project
	public query func get_project(id : ProjectID) : async Text {
		return "";
	};

	// Create Project
	public shared ({ caller }) func create_project() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Update Project
	public shared ({ caller }) func update_project() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Delete Project
	public shared ({ caller }) func delete_project() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Create Feedback Topic
	public shared ({ caller }) func create_feedback_topic() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// ------------------------- Snaps -------------------------
	// Get Snap
	public query func get_snap(id : SnapID) : async Text {
		return "";
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
