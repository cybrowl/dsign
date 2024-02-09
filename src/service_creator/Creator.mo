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

	//// Profile
	// check_user_has_a_username (needs to go to username registry)

	// get_number_of_users

	// create_profile
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

		// create profile
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

	// update_profile_avatar
	// update_profile_banner
	// get_profile

	//// Favorite
	// save_project_as_fav
	// delete_project_from_favs
	// get_all_fav_projects

	//// Project
	// create_project
	// edit_project
	// delete_projects
	// delete_snaps_from_project
	// add_snaps_to_project
	// update_project_metrics

	// create_topic

	// get_projects
	// owner_check

	//// Snap
	// create_snap
	// edit_snap
	// delete_snaps
	// delete_images
	// delete_design_file
	// get_all_snaps

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
