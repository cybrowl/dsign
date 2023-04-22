import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import AssetTypes "../service_assets/types";
import ImgAssetTypes "../service_assets_img/types";
import ICInterfaceTypes "../types/ic.types";

module {
	public type Time = Int;
	public type UserPrincipal = Principal;
	public type ProjectCanisterID = Text;
	public type ProjectID = Text;
	public type Username = Text;
	public type ProjectIDStorage = HashMap.HashMap<ProjectCanisterID, [ProjectID]>;
	public type SnapID = Text;

	public type AssetRef = AssetTypes.AssetRef;
	public type ImageRef = ImgAssetTypes.ImageRef;

	public type ICInterface = ICInterfaceTypes.Self;

	public type SnapRef = {
		id : Text;
		canister_id : Text;
	};

	public type ProjectRef = {
		id : Text;
		canister_id : Text;
	};

	public type Snap = {
		canister_id : Text;
		created : Time;
		file_asset : AssetRef;
		id : SnapID;
		image_cover_location : Nat8;
		images : [ImageRef];
		project : ?Project;
		tags : ?[Text];
		title : Text;
		username : Username;
		owner : ?Principal;
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

	public type Project = {
		id : Text;
		canister_id : Text;
		created : Time;
		username : Text;
		owner : UserPrincipal;
		name : Text;
		snaps : [SnapRef];
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

	public type ProjectUpdateAction = {
		#LikeAdd;
		#LikeRemove;
	};

	public type SnapPublic = {
		canister_id : Text;
		created : Time;
		file_asset : AssetRef;
		id : SnapID;
		image_cover_location : Nat8;
		images : [ImageRef];
		project : ?ProjectPublic;
		tags : ?[Text];
		title : Text;
		username : Username;
		owner : Null;
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

	public type ProjectPublic = {
		id : Text;
		canister_id : Text;
		created : Time;
		username : Text;
		name : Text;
		owner : Null;
		snaps : [SnapPublic];
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

	public type UpdateProject = {
		name : ?Text;
	};

	// Errors
	public type ErrCreateProject = {
		#NotAuthorized;
		#NameTooLarge;
		#NumberSnapsTooLarge;
		#UserAnonymous;
		#UserNotFound;
		#UsernameNotFound;
		#NotImplemented;
		#ErrorCall : Text;
	};

	public type ErrDeleteProjects = {
		#NumberSnapsTooLarge;
		#NotAuthorized;
		#UserNotFound;
		#ProjectIdsDoNotMatch;
	};

	public type ErrDeleteSnapsFromProject = {
		#NumberSnapsTooLarge;
		#NotAuthorized;
		#NotOwner;
		#ProjectNotFound;
		#ProjectIdsDoNotMatch;
		#UserNotFound;
		#ErrorCall : Text;
	};

	public type ErrAddSnapsToProject = {
		#NumberSnapsTooLarge;
		#NotAuthorized;
		#NotOwner;
		#ProjectNotFound;
		#ProjectIdsDoNotMatch;
		#UserNotFound;
		#ErrorCall : Text;
	};

	public type ErrUpdateProject = {
		#NotAuthorized : Bool;
		#ProjectIdsDoNotMatch : Bool;
		#ProjectNotFound : Bool;
		#UserNotFound : Bool;
		#ErrorCall : Text;
	};

	public type ErrGetProjects = {
		#UserNotFound : Bool;
		#NoProjects : Bool;
		#ErrorCall : Text;
	};

	// Actor Interface
	public type ProjectActor = actor {
		create_project : shared (Text, ?[SnapRef], UserPrincipal) -> async Result.Result<Project, ErrCreateProject>;
		delete_projects : shared ([ProjectID]) -> async ();
		delete_snaps_from_project : shared ([SnapRef], ProjectID, Principal) -> async Result.Result<Text, ErrDeleteSnapsFromProject>;
		add_snaps_to_project : shared ([SnapRef], ProjectID, Principal) -> async Result.Result<Project, ErrAddSnapsToProject>;
		update_project_details : shared (UpdateProject, ProjectRef) -> async Result.Result<Project, ErrUpdateProject>;
		update_snap_metrics : shared (ProjectID, ProjectUpdateAction) -> async Result.Result<(), ErrUpdateProject>;
		owner_check : query (ProjectID, Principal) -> async Bool;
		get_projects : query ([ProjectID]) -> async [ProjectPublic];
		get_projects_actor : query ([ProjectID]) -> async [Project];
	};
};
