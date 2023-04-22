import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import ProjectTypes "../service_projects/types";
import Result "mo:base/Result";
import ICInterfaceTypes "../types/ic.types";

module {
	public type FavoriteCanisterID = Text;
	public type FavoriteID = Text;
	public type FavoriteIDStorage = HashMap.HashMap<FavoriteCanisterID, [FavoriteID]>;

	public type ICInterface = ICInterfaceTypes.Self;
	public type ICInterfaceStatusResponse = ICInterfaceTypes.StatusResponse;

	public type ErrSaveFavorite = {
		#ErrorCall : Text;
		#SnapAlreadySaved : Bool;
		#NotAuthorized : Bool;
		#UserNotFound : Bool;
	};

	public type ErrGetFavorite = {
		#ErrorCall : Text;
		#SnapsEmpty : Bool;
		#NotAuthorized : Bool;
		#UserNotFound : Bool;
	};

	public type ErrDeleteFavorite = {
		#NotAuthorized : Bool;
		#UserNotFound : Bool;
		#FavoriteIdsDoNotMatch : Bool;
		#SnapNotFound : Bool;
	};

	// Actor Interface
	public type FavoriteActor = actor {

	};
};
