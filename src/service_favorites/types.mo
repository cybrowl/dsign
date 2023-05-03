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
		#ArgsTooLong : Bool;
		#ErrorCall : Text;
		#NotAuthorized : Bool;
		#ProjectAlreadySaved : Bool;
		#UserNotFound : Bool;
	};

	public type ErrGetFavorite = {
		#ErrorCall : Text;
		#ProjectsEmpty : Bool;
		#NotAuthorized : Bool;
		#UserNotFound : Bool;
	};

	public type ErrDeleteFavorite = {
		#ArgsTooLong : Bool;
		#ErrorCall : Text;
		#FavoriteIdNotFound : Bool;
		#NotAuthorized : Bool;
		#NotOwner : Bool;
		#ProjectNotFound : Bool;
		#UserNotFound : Bool;
	};

	// Actor Interface
	public type FavoriteActor = actor {
		save_project : shared (ProjectRef) -> async Result.Result<ProjectRef, ErrSaveFavorite>;
		delete_project : shared (ProjectID) -> async Result.Result<ProjectRef, ErrDeleteFavorite>;
		get_all_projects : shared ([ProjectID]) -> async Result.Result<[ProjectPublic], ErrGetFavorite>;
	};
};
