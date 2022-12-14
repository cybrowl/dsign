import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import AssetTypes "../service_assets/types";
import ImgAssetTypes "../service_assets_img/types";
import ProjectTypes "../service_projects/types";
import ICInterfaceTypes "../types/ic.types";

module {
	public type Time = Int;
	public type Username = Text;
	public type UserPrincipal = Principal;

	public type ImageRef = ImgAssetTypes.ImageRef;
	public type ImageAssetsActor = ImgAssetTypes.ImageAssetsActor;

	public type AssetRef = AssetTypes.AssetRef;
	public type AssetsActor = AssetTypes.AssetsActor;
	public type CreateAssetArgs = AssetTypes.CreateAssetArgs;

	public type Project = ProjectTypes.Project;
	public type ProjectActor = ProjectTypes.ProjectActor;
	public type ProjectRef = ProjectTypes.ProjectRef;

	public type ICInterface = ICInterfaceTypes.Self;
	public type ICInterfaceStatusResponse = ICInterfaceTypes.StatusResponse;

	// Snap
	public type SnapCanisterID = Text;
	public type SnapID = Text;
	public type SnapIDStorage = HashMap.HashMap<SnapCanisterID, [SnapID]>;

	public type ProjectPublic = {
		id : Text;
		canister_id : Text;
		created : Time;
		username : Text;
		name : Text;
		snaps : [SnapRef];
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

	public type SnapRef = {
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

	public type SnapUpdateArgs = {
		id : SnapID;
		image_cover_location : ?Nat8;
		images : ?[ImageRef];
		tags : ?[Text];
		title : ?Text;
	};

	public type CreateSnapArgs = {
		title : Text;
		image_cover_location : Nat8;
		img_asset_ids : [Nat];
		file_asset : ?{
			is_public : Bool;
			content_type : Text;
			chunk_ids : [Nat];
		};
	};

	public type InitArgs = {
		project_main_canister_id : ?Text;
		favorite_main_canister_id : ?Text;
	};

	// Errors
	public type ErrCreateSnap = {
		#UserAnonymous;
		#NoImageToSave;
		#FourImagesMax;
		#UsernameNotFound;
		#Unauthorized;
		#UserNotFound;
		#ErrorCall : Text;
	};

	public type ErrUpdateSnap = {
		#ErrorCall : Text;
		#NotAuthorized : Bool;
		#SnapNotFound : Bool;
	};

	public type ErrDeleteSnaps = {
		#UserNotFound;
		#SnapIdsDoNotMatch;
	};

	public type ErrGetAllSnaps = {
		#UserNotFound : Bool;
	};

	// Actor Interface
	public type SnapActor = actor {
		create_snap : shared (CreateSnapArgs, [ImageRef], AssetRef, UserPrincipal) -> async Result.Result<Snap, ErrCreateSnap>;
		update_snap_metrics : shared (SnapID) -> async Result.Result<SnapPublic, ErrUpdateSnap>;
		delete_snaps : shared ([SnapID]) -> async ();
		delete_project_from_snaps : shared ([SnapRef]) -> async ();
		add_project_to_snaps : shared (ProjectRef) -> async ();
		get_all_snaps : query ([SnapID]) -> async [SnapPublic];
	};
};
