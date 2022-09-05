import Principal "mo:base/Principal";

// service_profile
module {
    public type Username = Text;
    public type UserPrincipal = Principal;

    public type Profile = {
        avatar: {
            id: Text;
            canister_id: Text;
            url: Text;
            exists: Bool;
        };
        created: Int;
        username: Username;
    };

    public type ProfileOk = {
        profile: Profile;
    };

    public type ProfileErr = {
        #ProfileNotFound;
        #ErrorCall: Text;
    };
}
