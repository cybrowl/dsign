import Principal "mo:base/Principal";

module {
    public type Username = Text;
    public type UserPrincipal = Principal;

    public type UsernameError = {
        #UsernameInvalid;
        #UsernameTaken;
        #UserNotFound;
        #UserHasUsername;
    };
}
