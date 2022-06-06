import Principal "mo:base/Principal";

// service_profile
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

    public type AvatarImgOk = {
        avatar_url: Text;
    };

    public type ProfileError = {
        #ProfileNotFound;
    };
}
