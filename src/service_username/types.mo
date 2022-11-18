import Principal "mo:base/Principal";
import Text "mo:base/Text";

module {
	public type Username = Text;
	public type UserPrincipal = Principal;

	public type ErrUsername = {
		#UserAnonymous;
		#UserHasUsername;
		#UsernameInvalid;
		#UsernameTaken;
		#UsernameNotFound;
		#UserNotFound;
	};
};
