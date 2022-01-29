import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import Types "./types";

actor Profile = {
    type UserID = Types.UserID;
    type Profile = Types.Profile;

    var profiles : HashMap.HashMap<UserID, Profile> = HashMap.HashMap(1, Text.equal, Text.hash);

    public query func ping() : async Text {
        return "meow";
    };

    public shared (msg) func create() : async () {
        //TODO: create
    };
};
