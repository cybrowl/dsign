import Principal "mo:base/Principal";

// import ICInterfaceTypes "../types/ic.types";
import ImgAssetTypes "../service_assets_img/types";
import AssetTypes "../service_assets/types";

module {
	public type Username = Text;
	public type UserPrincipal = Principal;
	public type Time = Int;

	// public type ICInterface = ICInterfaceTypes.Self;
	// public type ImageAssetsActor = ImgAssetTypes.ImageAssetsActor;

	// Asset
	public type AssetRef = AssetTypes.AssetRef;

	// Images
	public type ImageRef = ImgAssetTypes.ImageRef;

	// Profile
	public type Profile = {
		avatar : {
			id : Text;
			canister_id : Text;
			url : Text;
			exists : Bool;
		};
		banner : {
			id : Text;
			canister_id : Text;
			url : Text;
			exists : Bool;
		};
		created : Int;
		storage_mb_used : Nat;
		username : Username;
		projects : [ProjectID];
	};

	public type ErrProfile = {
		#ProfileNotFound : Bool;
		#ProfileInvalidArgs : Bool;
		#PrincipalNotFoundForUsername;
		#ErrorCall : Text;
	};

	public type ErrUsername = {
		#UserAnonymous;
		#UserHasUsername;
		#UserNotAuthorized;
		#UsernameInvalid;
		#UsernameTaken;
		#UsernameNotFound;
		#UserNotFound;
		#MaxUsers;
	};

	// Project
	public type ProjectID = Text;

	public type ProjectRef = {
		id : Text;
		canister_id : Text;
	};

	type File = {
		created : Time;
		name : Text;
		size : Nat;
		url : Text;
	};

	type Message = {
		created : Time;
		content : Text;
		username : Text;
	};

	public type Topic = {
		id : Text;
		snap_ref : SnapRef;
		snap_name : Text;
		name : Text;
		file : ?File;
		messages : [Message];
	};

	public type Feedback = {
		topics : [Topic];
	};

	public type Project = {
		id : Text;
		canister_id : Text;
		created : Time;
		description : ?Text;
		username : Text;
		owner : UserPrincipal;
		name : Text;
		snaps : [SnapID];
		feedback : ?Feedback;
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

	// Snap
	public type SnapID = Text;

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
		project_ref : ?ProjectRef;
		title : Text;
		tags : [Text];
		username : Username;
		owner : ?Principal;
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

};
