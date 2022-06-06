import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";

actor class Profile() = {
    type Profile = Types.Profile;
    type ProfileError = Types.ProfileError;
    type ProfileOk = Types.ProfileOk;
    type Username = Types.Username;
    type UserPrincipal =  Types.UserPrincipal;

    let ACTOR_NAME : Text = "Profile";

    var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(0, Principal.equal, Principal.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public query ({caller}) func get_profile() : async Result.Result<ProfileOk, ProfileError> {
        switch (profiles.get(caller)) {
            case (null) {
                #err(#ProfileNotFound)
            };
            case (?profile) {
                return #ok({profile});
            };
        };
    };

    public shared func create_profile(principal: UserPrincipal, username: Username) : async () {
        let profile : Profile = {
            avatar_url = "";
            created = Time.now();
            username = username;
        };

        profiles.put(principal, profile);
    };
};
