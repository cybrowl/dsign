import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import AssetTypes "../service_assets/types";
import ImgAssetTypes "../service_assets_img/types";

module {
	public type Time = Int;
	public type UserPrincipal = Principal;
	public type ProjectCanisterID = Text;
	public type ProjectID = Text;
	public type ProjectIDStorage = HashMap.HashMap<ProjectCanisterID, [ProjectID]>;
	public type SnapID = Text;

	public type AssetRef = AssetTypes.AssetRef;
	public type ImageRef = ImgAssetTypes.ImageRef;

	public type SnapRef = {
		id : Text;
		canister_id : Text;
	};

	public type ProjectRef = {
		id : Text;
		canister_id : Text;
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
		username : Text;
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
		snaps : [SnapPublic];
	};

	public type Project = {
		id : Text;
		canister_id : Text;
		created : Time;
		username : Text;
		owner : UserPrincipal;
		name : Text;
		snaps : [SnapRef];
	};

	public type ErrCreateProject = {
		#NotAuthorized;
		#UserAnonymous;
		#UserNotFound;
		#UsernameNotFound;
		#NotImplemented;
		#ErrorCall : Text;
	};

	public type ErrDeleteProjects = {
		#NotAuthorized;
		#UserNotFound;
		#ProjectIdsDoNotMatch;
	};

	public type ErrDeleteSnapsFromProject = {
		#NotAuthorized;
		#NotOwner;
		#ProjectNotFound;
		#ProjectIdsDoNotMatch;
		#UserNotFound;
		#ErrorCall : Text;
	};

	public type ErrAddSnapsToProject = {
		#NotAuthorized;
		#NotOwner;
		#ProjectNotFound;
		#ProjectIdsDoNotMatch;
		#UserNotFound;
		#ErrorCall : Text;
	};

	public type ErrGetProjects = {
		#UserNotFound : Bool;
		#NoProjects : Bool;
	};

	// Actor Interface
	public type ProjectActor = actor {
		create_project : shared (Text, ?[SnapRef], UserPrincipal) -> async Result.Result<Project, ErrCreateProject>;
		delete_projects : shared ([ProjectID]) -> async ();
		delete_snaps_from_project : shared ([SnapRef], ProjectID, Principal) -> async Result.Result<Text, ErrDeleteSnapsFromProject>;
		add_snaps_to_project : shared ([SnapRef], ProjectID, Principal) -> async Result.Result<Text, ErrAddSnapsToProject>;
		get_projects : query ([ProjectID]) -> async [ProjectPublic];
		get_projects_actor : query ([ProjectID]) -> async [Project];
	};
};
