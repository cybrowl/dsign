import Principal "mo:base/Principal";
import Result "mo:base/Result";

// import ICInterfaceTypes "../types/ic.types";

module {
	public type CanisterID = Text;
	public type FavoriteID = Text;
	public type FileAssetID = Text;
	public type ProjectID = Text;
	public type SnapID = Text;
	public type Time = Int;
	public type Username = Text;
	public type UserPrincipal = Principal;

	// public type ICInterface = ICInterfaceTypes.Self;

	public type Metrics = {
		likes : Nat;
		views : Nat;
	};

	// File Asset
	type ContentEncoding = {
		#Identity;
		#GZIP;
	};

	public type FileAsset = {
		id : FileAssetID;
		canister_id : Text;
		chunks_size : Nat;
		content_encoding : ContentEncoding;
		content_size : Nat;
		content_type : Text;
		created : Int;
		filename : Text;
		url : Text;
	};

	// Profile
	public type ArgsUpdateProfile = {
		id : Text;
		canister_id : Text;
		url : Text;
	};

	type StorageMetrics = {
		text : Nat;
		images : Nat;
		files : Nat;
		total : Nat;
	};

	public type Profile = {
		avatar : {
			id : Text;
			canister_id : CanisterID;
			url : Text;
		};
		banner : {
			id : Text;
			canister_id : CanisterID;
			url : Text;
		};
		created : Int;
		canister_id : CanisterID;
		username : Username;
		owner : UserPrincipal;
		projects : [ProjectID];
		favorites : [FavoriteID];
		storage_metrics : ?StorageMetrics;
	};

	public type ProfilePublic = {
		avatar : {
			id : Text;
			canister_id : CanisterID;
			url : Text;
		};
		banner : {
			id : Text;
			canister_id : CanisterID;
			url : Text;
		};
		created : Int;
		canister_id : CanisterID;
		username : Username;
		is_owner : Bool;
		projects : [ProjectPublic];
		favorites : [Project];
		storage_metrics : ?StorageMetrics;
	};

	public type ErrProfile = {
		#NotAuthorizedCaller;
		#MaxUsersExceeded;
		#ProfileNotFound : Bool;
		#InvalidProfileArguments : Bool;
		#UsernamePrincipalNotFound;
	};

	// Project
	public type ArgsCreateProject = {
		name : Text;
		description : ?Text;
	};

	public type ArgsUpdateProject = {
		id : ProjectID;
		name : ?Text;
		description : ?Text;
	};

	public type Project = {
		id : ProjectID;
		canister_id : CanisterID;
		created : Time;
		name : Text;
		description : ?Text;
		username : Text;
		owner : UserPrincipal;
		snaps : [SnapID];
		feedback : ?Feedback;
		metrics : Metrics;
	};

	public type ProjectPublic = {
		id : ProjectID;
		canister_id : CanisterID;
		created : Time;
		name : Text;
		description : ?Text;
		username : Text;
		owner : ?UserPrincipal;
		is_owner : Bool;
		snaps : [SnapID];
		feedback : ?Feedback;
		metrics : Metrics;
	};

	public type ProjectRef = {
		id : ProjectID;
		canister_id : CanisterID;
	};

	public type ErrProject = {
		#ProfileNotFound : Bool;
		#ProjectNotFound : Bool;
		#NotOwner : Bool;
	};

	// Project Feedback
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
		design_file : ?FileAsset;
		messages : [Message];
	};

	public type Feedback = {
		topics : [Topic];
	};

	// Snap
	public type ArgsCreateSnap = {
		project_id : ProjectID;
		name : Text;
		tags : ?[Text];
		design_file : ?FileAsset;
		images : [FileAsset];
		image_cover_location : Nat8;
	};

	public type ArgsUpdateSnap = {
		id : SnapID;
		name : ?Text;
		tags : ?[Text];
		design_file : ?FileAsset;
		images : ?[FileAsset];
		image_cover_location : ?Nat8;
	};

	public type Snap = {
		id : SnapID;
		project_id : ProjectID;
		canister_id : CanisterID;
		created : Time;
		updated : Time;
		name : Text;
		tags : [Text];
		username : Username;
		owner : UserPrincipal;
		design_file : ?FileAsset;
		image_cover_location : Nat8;
		images : [FileAsset];
		metrics : Metrics;
	};

	public type SnapPublic = {
		id : SnapID;
		project_id : ProjectID;
		canister_id : CanisterID;
		created : Time;
		updated : Time;
		name : Text;
		tags : [Text];
		username : Username;
		owner : ?UserPrincipal;
		design_file : ?FileAsset;
		image_cover_location : Nat8;
		images : [FileAsset];
		metrics : Metrics;
	};

	public type SnapRef = {
		id : SnapID;
		canister_id : CanisterID;
	};

	public type ErrSnap = {
		#ProfileNotFound : Bool;
		#ProjectNotFound : Bool;
		#SnapNotFound : Bool;
		#NotOwner : Bool;
	};

	// Actor Interface
	public type CreatorActor = actor {
		create_profile : shared (Username, UserPrincipal) -> async Result.Result<Username, ErrProfile>;
	};
};
