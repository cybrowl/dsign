import Principal "mo:base/Principal";

module {
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Principal;

    public type Profile = {
        avatar_url: Text;
        created: Time;
        username: Username;
    };

    public type ProfileOk = {
        profile: Profile;
    };

    public type ProfileError = {
        #ProfileNotFound;
    };
}
