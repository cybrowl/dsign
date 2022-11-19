import Principal "mo:base/Principal";

import ICInterfaceTypes "../types/ic.types";
import ImgAssetTypes "../service_assets_img/types";

module {
	public type Username = Text;
	public type UserPrincipal = Principal;

	public type ICInterface = ICInterfaceTypes.Self;
	public type ImageAssetsActor = ImgAssetTypes.ImageAssetsActor;

	public type Profile = {
		avatar : {
			id : Text;
			canister_id : Text;
			url : Text;
			exists : Bool;
		};
		created : Int;
		username : Username;
	};

	public type ErrProfile = {
		#ProfileNotFound;
		#PrincipalNotFoundForUsername;
		#ErrorCall : Text;
	};

	public type ErrUsername = {
		#UserAnonymous;
		#UserHasUsername;
		#UsernameInvalid;
		#UsernameTaken;
		#UsernameNotFound;
		#UserNotFound;
	};
};
