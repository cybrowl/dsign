module {
    public type Username = Text;
    public type UserPrincipal = Text;

    public type UsernameError = {
        #UsernameInvalid;
        #UsernameTaken;
        #UserNotFound;
    };
}
