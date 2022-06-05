import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Types "./types";

actor class Profile() = {
    type UserPrincipal =  Types.UserPrincipal;
    type Profile = Types.Profile;
    type ProfileError = Types.ProfileError;

    let ACTOR_NAME : Text = "Profile";

    var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(0, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
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
