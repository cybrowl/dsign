import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

module {
	public type Time = Int;
	public type UserPrincipal = Principal;
	public type ProjectCanisterID = Text;
	public type ProjectID = Text;
	public type ProjectIDStorage = HashMap.HashMap<ProjectCanisterID, [ProjectID]>;

	public type SnapRef = {
		id : Text;
		canister_id : Text;
	};

	public type ProjectRef = {
		id : Text;
		canister_id : Text;
	};

	public type Project = {
		id : Text;
		canister_id : Text;
		created : Time;
		username : Text;
		owner : Principal;
		name : Text;
		snaps : [SnapRef];
	};

	public type CreateProjectErr = {
		#NotAuthorized;
		#UserAnonymous;
		#UserNotFound;
		#UsernameNotFound;
		#NotImplemented;
		#ErrorCall : Text;
	};

	public type DeleteProjectsErr = {
		#UserNotFound;
	};

	public type DeleteSnapsFromProjectErr = {
		#NotAuthorized;
		#NotOwner;
		#ProjectNotFound;
		#ErrorCall : Text;
	};

	public type GetProjectsErr = {
		#UserNotFound;
	};

	// Actor Interface
	public type ProjectActor = actor {
		create_project : shared (Text, ?[SnapRef], UserPrincipal) -> async Result.Result<Project, CreateProjectErr>;
		delete_projects : shared ([ProjectID]) -> async ();
		delete_snaps_from_project : shared ([SnapRef], ProjectID, Principal) -> async Result.Result<Text, DeleteSnapsFromProjectErr>;
		get_projects : query ([ProjectID]) -> async [Project];
	};
};
