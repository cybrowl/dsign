import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

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
};
