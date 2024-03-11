import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {
	public type Username = Text;

	public type UsernameInfo = {
		canister_id : Text;
		username : Text;
	};

	public type ErrUsername = {
		#CallerAnonymous : Bool;
		#UsernameInvalid : Bool;
		#UsernameTaken : Bool;
		#UserPrincipalNotFound : Bool;
		#UsernameNotFound : Bool;
		#ErrorCall : Text;
	};

	public type UsernameRegistryActor = actor {
		get_username_by_principal : shared (Principal) -> async Result.Result<Username, ErrUsername>;
	};
};
