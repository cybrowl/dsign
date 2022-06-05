module {
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Text;

    public type UsernameError = {
        #UserNotFound;
        #UsernameTaken;
    };

    public type Profile = {
        avatar: Text;
        created: Time;
        username: Username;
    };
}
