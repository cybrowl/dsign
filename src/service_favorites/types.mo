import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import ProjectTypes "../service_projects/types";
import Result "mo:base/Result";
import SnapTypes "../service_snaps/types";

module {
	public type FavoriteCanisterID = Text;
	public type FavoriteID = Text;
	public type FavoriteIDStorage = HashMap.HashMap<FavoriteCanisterID, [FavoriteID]>;

	public type SnapCanisterId = Text;
	public type SnapID = Text;
	public type SnapPublic = SnapTypes.SnapPublic;
	public type SnapRef = SnapTypes.SnapRef;

	public type SnapActor = SnapTypes.SnapActor;

	public type ErrSaveFavorite = {
		#ErrorCall : Text;
		#NotAuthorized : Bool;
		#UserNotFound : Bool;
	};

	public type ErrGetFavorite = {
		#ErrorCall : Text;
		#NoSnaps : Bool;
		#NotAuthorized : Bool;
		#UserNotFound : Bool;
	};

	public type ErrDeleteFavorite = {
		#NotAuthorized : Bool;
		#SnapNotFound : Bool;
	};

	// Actor Interface
	public type FavoriteActor = actor {
		save_snap : shared (SnapPublic, Principal) -> async Result.Result<SnapPublic, ErrSaveFavorite>;
		delete_snap : shared (SnapID) -> async Result.Result<SnapPublic, ErrDeleteFavorite>;
		get_all_snaps : query ([SnapID]) -> async Result.Result<[SnapPublic], ErrGetFavorite>;
	};
};
