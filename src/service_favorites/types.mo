import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import ProjectTypes "../service_projects/types";
import Result "mo:base/Result";
import ICInterfaceTypes "../types/ic.types";

module {
	public type FavoriteCanisterID = Text;
	public type FavoriteID = Text;
	public type FavoriteIDStorage = HashMap.HashMap<FavoriteCanisterID, [FavoriteID]>;
	public type ProjectRef = ProjectTypes.ProjectRef;
	public type ProjectPublic = ProjectTypes.ProjectPublic;
	public type ProjectID = ProjectTypes.ProjectID;

	public type ProjectActor = ProjectTypes.ProjectActor;

	public type ICInterface = ICInterfaceTypes.Self;
	public type ICInterfaceStatusResponse = ICInterfaceTypes.StatusResponse;

	public type ErrSaveFavorite = {
		#ErrorCall : Text;
		#ProjectAlreadySaved : Bool;
		#NotAuthorized : Bool;
		#ArgsTooLong : Bool;
		#UserNotFound : Bool;
	};

	public type ErrGetFavorite = {
		#ErrorCall : Text;
		#ProjectsEmpty : Bool;
		#NotAuthorized : Bool;
		#UserNotFound : Bool;
	};

	public type ErrDeleteFavorite = {
		#NotAuthorized : Bool;
		#UserNotFound : Bool;
		#FavoriteIdsDoNotMatch : Bool;
		#ProjectNotFound : Bool;
	};

	// Actor Interface
	public type FavoriteActor = actor {
		save_project : shared (ProjectRef) -> async Result.Result<ProjectRef, ErrSaveFavorite>;
		get_all_projects : shared ([ProjectID]) -> async Result.Result<[ProjectPublic], ErrGetFavorite>;
	};
};
