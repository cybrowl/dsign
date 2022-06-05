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

    let ACTOR_NAME : Text = "Profile";

    var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(1, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
    };
};
