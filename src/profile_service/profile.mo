import Cycles "mo:base/ExperimentalCycles";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Logger "canister:logger";
import Types "./types";

actor class Profile() = this {
    type UserID = Types.UserID;
    type Username = Types.Username;
    type Profile = Types.Profile;
    type ProfileError = Types.ProfileError;
    type Tags = Types.Tags;

    let ACTOR_NAME : Text = "Profile";

    var profiles : HashMap.HashMap<UserID, Profile> = HashMap.HashMap(1, Text.equal, Text.hash);
    var isProduction : Bool = false;
    var host : Text = "";

    if (isProduction) {
        host := "https://kqlfj-siaaa-aaaag-aaawq-cai.raw.ic0.app";
    } else {
        host := "http://127.0.0.1:8000";
    };

    public query func ping() : async Text {
        return "meow";
    };

    public query func get_cycles_balance() : async Nat {
        return Cycles.balance();
    };

    public func is_full() : async Bool {
        // TODO: change to query
        let MAX_SIZE_THRESHOLD_MB : Float = 3500;

        let rtsMemorySize : Nat = Prim.rts_memory_size();
        let memSize : Float = Float.fromInt(rtsMemorySize);
        let memoryInMegabytes =  Float.abs(memSize * 0.000001);

        if (memoryInMegabytes > MAX_SIZE_THRESHOLD_MB) {
            return true;
        } else {
            return false;
        }
    };

    public func create(userId : UserID, username : Username) : async () {
        // let specialtyFields : [Tags] = [["designer"]];

        let profile : Profile = {
            avatar = "";
            username = username;
            created = Time.now();
            website = "";
        };

        profiles.put(userId, profile);
    };

    public func set_avatar(userId : UserID, username : Username) : async () {
        switch (profiles.get(userId)) {
            case (?profile) {
                let profileUpdated : Profile =  {
                    avatar = Text.join("", ([host,"/avatar/",username].vals()));
                    username = profile.username;
                    created = profile.created;
                    website = profile.website;
                };

                profiles.put(userId, profileUpdated);
            };
            case(_) { };
        };
    };

    public query func get_profile(userId : UserID) : async Result.Result<Profile, ProfileError> {
        switch (profiles.get(userId)) {
            case (null) {
                #err(#ProfileNotFound)
            };
            case (?profile) {
                return #ok(profile);
            };
        };
    };

    system func heartbeat() : async () {
        let tags = [ACTOR_NAME, "heartbeat"];

        let canisterId : Text = Principal.toText(Principal.fromActor(this));

        if (isProduction == false) {
            if (Text.equal(canisterId, "inwlb-baaaa-aaaag-aaaza-cai")) {
                isProduction := true;
            };
        };
    };
};
