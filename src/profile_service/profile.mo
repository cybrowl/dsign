import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Types "./types";

actor Profile = {
    type UserID = Types.UserID;
    type Profile = Types.Profile;

    var profiles : HashMap.HashMap<UserID, Profile> = HashMap.HashMap(1, Text.equal, Text.hash);

    public query func ping() : async Text {
        return "meow";
    };

    public shared (msg) func create() : async Hash.Hash {
        //TODO: create
    };
};
