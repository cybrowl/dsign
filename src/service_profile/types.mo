module {
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Text;

    public type Profile = {
        avatar_url: Text;
        created: Time;
        username: Username;
    };
}
