import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Float "mo:base/Float";

import Logger "canister:logger";
import Types "./types";

actor class Profile() = {
    type UserID = Types.UserID;
    type Profile = Types.Profile;
    type HealthStats = Types.HealthStats;

    var profiles : HashMap.HashMap<UserID, Profile> = HashMap.HashMap(1, Text.equal, Text.hash);

    public query func ping() : async Text {
        return "meow";
    };

    public query func get_health_stats() : async HealthStats {
        let healthStats : HealthStats = {
            rtsMemorySize = Prim.rts_memory_size();
            profileActorMapSize = profiles.size();
        };

        return healthStats;
    };

    public func is_full() : async Bool {
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
};
