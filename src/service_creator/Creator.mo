import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import Types "./types";

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

	// ------------------------- Variables -------------------------
	let VERSION : Nat = 3;

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

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	//// Profile
	// check_username_is_available (needs to go to username registry)
	// check_user_has_a_username
	// get_current_username
	// create_username
	// get_number_of_users
	// get_username
	// get_username_public
	// get_user_principal_public

	// update_profile_avatar
	// update_profile_banner
	// get_profile
	// get_profile_public

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
};
