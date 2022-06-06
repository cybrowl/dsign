import Principal "mo:base/Principal";

module {
    public type Username = Text;
    public type UserPrincipal = Principal;

    public type UsernameError = {
        #UserAnonymous;
        #UserHasUsername;
        #UsernameInvalid;
        #UsernameTaken;
        #UserNotFound;
    };
}
