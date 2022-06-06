import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";

actor class Profile() = {
    type Profile = Types.Profile;
    type ProfileError = Types.ProfileError;
    type Username = Types.Username;
    type UserPrincipal =  Types.UserPrincipal;

    let ACTOR_NAME : Text = "Profile";

    var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(0, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public shared ({caller}) func create_profile(principal: UserPrincipal, username: Username) : async () {
        let principal : UserPrincipal = Principal.toText(caller);

        //TODO: set avatar url
        let profile : Profile = {
            avatar_url = "";
            created = Time.now();
            username = username;
        };

        profiles.put(principal, profile);
    };

    public query ({caller}) func get_profile() : async Result.Result<Profile, ProfileError> {
        let principal : UserPrincipal = Principal.toText(caller);

        switch (profiles.get(principal)) {
            case (null) {
                #err(#ProfileNotFound)
            };
            case (?profile) {
                return #ok(profile);
            };
        };
    };
};
