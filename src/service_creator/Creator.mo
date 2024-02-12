import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Logger "canister:logger";

import Types "./types";
import Utils "./utils";

actor Creator = {
	type ErrProfile = Types.ErrProfile;
	type ErrUsername = Types.ErrUsername;
	type Profile = Types.Profile;
	type Project = Types.Project;
	type ProjectID = Types.ProjectID;
	type ProjectRef = Types.ProjectRef;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type Username = Types.Username;
	type UserPrincipal = Types.UserPrincipal;

	//NOTE: This canister will only hold 100 users, each using 20MB each around 2GB
	// Once 100 users is reached it will create another instace of itself.
	// Images and Files will be stored in scalable storage units.

	// ------------------------- Variables -------------------------
	let VERSION : Nat = 1;
	let CANISTER_ID : Text = "";
	let Max_Users : Nat = 100;
	stable var users : Nat = 0;

	// ------------------------- Storage Data -------------------------
	// profiles
	var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);

	// favorites (only lives within profile)
	var favorites : HashMap.HashMap<UserPrincipal, ProjectRef> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
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

	// Create Profile
	public shared ({ caller }) func create_profile(username : Username) : async Result.Result<Username, ErrUsername> {
		let tags = [("canister_id", CANISTER_ID), ("method", "create_username")];
		let is_anonymous = Principal.isAnonymous(caller);

		let valid_username : Bool = Utils.is_valid_username(username);
		// let user_has_username : Bool = check_user_has_a_username(caller);

		if (is_anonymous == true) {
			return #err(#UserAnonymous);
		};

		if (valid_username == false) {
			return #err(#UsernameInvalid);
		};

		if (users >= Max_Users) {
			return #err(#MaxUsers);
		};

		//TODO: check username_registry to see if username is taken
		// if (username_available == false) {
		//     return #err(#UsernameTaken);
		// };

		ignore Logger.log_event(tags, "created");

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
			storage_mb_used = 0;
			projects = [];
			username = username;
		};

		profiles.put(caller, profile);

		return #ok(username);
	};

	// Update Profile Avatar
	public shared ({ caller }) func update_profile_avatar(username : Username) : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Update Profile Banner
	public shared ({ caller }) func update_profile_banner(username : Username) : async Result.Result<Text, Text> {
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

	// ------------------------- Projects -------------------------
	// Get Number of Projects
	public query func total_projects() : async Nat {
		return projects.size();
	};

	// Get Projects
	public query func get_projects() : async Text {
		return "";
	};

	// Get Project Owner Status
	public query func get_project_owner_status() : async Text {
		return "";
	};

	// Create Project
	public shared ({ caller }) func create_project() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Add Snaps to Project
	public shared ({ caller }) func add_snaps_to_project() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// Create Feedback Topic
	public shared ({ caller }) func create_feedback_topic() : async Result.Result<Text, Text> {
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

	// Delete Snaps from Project
	public shared ({ caller }) func delete_snaps_from_project() : async Result.Result<Text, Text> {
		return #ok("");
	};

	// TODO: project metrics (likes & views)

	// ------------------------- Snaps -------------------------
	// Get Snaps
	public query func get_snaps() : async Text {
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
	public shared ({ caller }) func delete_snaps() : async Result.Result<Text, Text> {
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

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	// check_user_has_a_username (needs to go to username registry)
};
