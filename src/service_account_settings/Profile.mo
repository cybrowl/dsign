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

actor class Profile(accountSettingsPrincipalText : Text, avatarCanisterId : Text) = {
    type UserID = Types.UserID;
    type Username = Types.Username;
    type Profile = Types.Profile;
    type ProfileError = Types.ProfileError;
    type Tags = Types.Tags;

    let ACTOR_NAME : Text = "Profile";

    var profiles : HashMap.HashMap<UserID, Profile> = HashMap.HashMap(1, Text.equal, Text.hash);
    var isProduction : Bool = false;
    var host : Text = "";

    if (Text.equal(accountSettingsPrincipalText, "inwlb-baaaa-aaaag-aaaza-cai")) {
        isProduction := true;
    };

    if (isProduction) {
        host := Text.join("", (["https://", avatarCanisterId, ".raw.ic0.app"].vals()));
    } else {
        host := "http://127.0.0.1:8000";
    };

    // Canister Management
    public query func version() : async Text {
        return "0.0.2";
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

    // User Logic
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
        var profileAvatar : Text = "";

        if (isProduction) {
            profileAvatar := Text.join("", ([host,"/avatar/",username].vals()));
        } else {
            profileAvatar := Text.join("", ([host,"/avatar/",username, "?canisterId=", avatarCanisterId].vals()));
        };

        switch (profiles.get(userId)) {
            case (?profile) {
                let profileUpdated : Profile =  {
                    avatar = profileAvatar;
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
};
