import Principal "mo:base/Principal";
import Result "mo:base/Result";

// import ICInterfaceTypes "../types/ic.types";

module {
	public type CanisterID = Text;
	public type ProjectID = Text;
	public type FavoriteID = Text;
	public type SnapID = Text;
	public type Time = Int;
	public type Username = Text;
	public type UserPrincipal = Principal;

	// public type ICInterface = ICInterfaceTypes.Self;

	// Profile
	public type Profile = {
		avatar : {
			id : Text;
			canister_id : CanisterID;
			url : Text;
			exists : Bool;
		};
		banner : {
			id : Text;
			canister_id : CanisterID;
			url : Text;
			exists : Bool;
		};
		created : Int;
		username : Username;
		owner : UserPrincipal;
		projects : [ProjectID];
		favorites : [FavoriteID];
		storage : ?Storage;
	};

	// Profile Public
	public type ProfilePublic = {
		avatar : {
			id : Text;
			canister_id : CanisterID;
			url : Text;
			exists : Bool;
		};
		banner : {
			id : Text;
			canister_id : CanisterID;
			url : Text;
			exists : Bool;
		};
		created : Int;
		username : Username;
		is_owner : Bool;
		projects : [Project];
		favorites : [Project];
		storage : ?Storage;
	};

	public type ErrProfile = {
		#NotAuthorizedCaller;
		#MaxUsersExceeded;
		#ProfileNotFound : Bool;
		#InvalidProfileArguments : Bool;
		#UsernamePrincipalNotFound;
	};

	type Storage = {
		text : Nat;
		images : Nat;
		files : Nat;
		total : Nat;
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

	// Project
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
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

	public type ProjectRef = {
		id : ProjectID;
		canister_id : CanisterID;
	};

	// Snap
	public type Snap = {
		id : SnapID;
		canister_id : CanisterID;
		created : Time;
		title : Text;
		tags : [Text];
		username : Username;
		owner : UserPrincipal;
		file_asset : Bool;
		image_cover_location : Nat8;
		images : [Bool];
		project_ref : ProjectRef;
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

	public type SnapRef = {
		id : SnapID;
		canister_id : CanisterID;
	};

	// Actor Interface
	public type CreatorActor = actor {
		create_profile : shared (Username, UserPrincipal) -> async Result.Result<Username, ErrProfile>;
	};
};
