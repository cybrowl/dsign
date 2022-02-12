import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Logger "canister:logger";
import Profile "Profile";
import Types "./types";

actor ProfileManager {
    type AvatarActor = Types.AvatarActor;
    type AvatarError = Types.AvatarError;
    type Canister = Types.Canister;
    type CanisterID = Types.CanisterID;
    type Image = Types.Image;
    type Profile = Types.Profile;
    type ProfileActor = Types.ProfileActor;
    type ProfileManagerError = Types.ProfileManagerError;
    type UserID = Types.UserID;
    type Username = Types.Username;

    let ACTOR_NAME : Text = "ProfileManager";

    // User Data Management
    var userIds : HashMap.HashMap<Username, UserID> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var userIdsEntries : [(Username, UserID)] = [];

    var usernames : HashMap.HashMap<UserID, Username> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var usernamesEntries : [(UserID, Username)] = [];

    var canisterProfileIDs : HashMap.HashMap<UserID, CanisterID> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var canisterProfileIDsEntries : [(UserID, CanisterID)] = [];

    var canisterAvatarIDs : HashMap.HashMap<UserID, CanisterID> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var canisterAvatarIDsEntries : [(UserID, CanisterID)] = [];

    // Canister Management
    stable var anchorTime = Time.now();
    stable var currentEmptyProfileCanisterID : Text = "";
    stable var currentEmptyAvatarCanisterID : Text = "rno2w-sqaaa-aaaaa-aaacq-cai";

    var canisterCache : HashMap.HashMap<CanisterID, Canister> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var canisterCacheEntries : [(CanisterID, Canister)] = [];

    public func ping() : async Text {
        return "meow";
    };

    // User Data Management
    public query (msg) func has_account() : async Bool  {
        let userId : UserID = Principal.toText(msg.caller);

        switch (canisterProfileIDs.get(userId)) {
            // check user exists
            case (?canisterID) {
                return true;
            };
            case(_) { return false };
        };
    };

    public shared (msg) func set_avatar(avatar: Image) : async Result.Result<Text, AvatarError> {
        let tags = [ACTOR_NAME, "set_avatar"];
        let userId : UserID = Principal.toText(msg.caller);

        switch (usernames.get(userId)) {
            case (?username) {
                // save to get avatar canister id with userId
                canisterAvatarIDs.put(userId, currentEmptyAvatarCanisterID);

                // call avatar canister and set avatar
                let avatarActor = actor (currentEmptyAvatarCanisterID) : AvatarActor;
                await avatarActor.set(avatar, username);

                // call profile canister and set avatar URL
                let profileActor = actor (currentEmptyProfileCanisterID) : ProfileActor;
                await profileActor.set_avatar(userId, username);

                await Logger.log_event(tags, "avatar_created");
                #ok("avatar_created");
            };
            case (null) {
                await Logger.log_event(tags, "UsernameNotFound");
                #err(#UsernameNotFound)
            };
        };
    };

    public shared (msg) func create_profile(username: Username) : async Result.Result<Text, ProfileManagerError> {
        // NOTE: this should only be executed once by user
        let tags = [ACTOR_NAME, "create_profile"];
        let userId : UserID = Principal.toText(msg.caller);

        switch (canisterProfileIDs.get(userId)) {
            // check user exists
            case (?canisterID) {
                await Logger.log_event(tags, "userId_exists");
                #err(#UserIDExists)
            };
            case (null) {
                // check username available
                switch (userIds.get(username)) {
                    case (?userId) {
                        await Logger.log_event(tags, "username_taken");
                        #err(#UsernameTaken)
                    };
                    case (null) {
                        // save to get useId with username
                        userIds.put(username, userId);

                        // save to get username with userId
                        usernames.put(userId, username);

                        // save to get profile canister id with userId
                        canisterProfileIDs.put(userId, currentEmptyProfileCanisterID);

                        // create username in profile
                        let profile = actor (currentEmptyProfileCanisterID) : ProfileActor;
                        await profile.create(userId, username);

                        await Logger.log_event(tags, "profile_created");
                        #ok("profile_created");
                    };
                };
            };
        };
    };

    public shared (msg) func get_profile() : async Result.Result<Profile, ProfileManagerError> {
        let tags = [ACTOR_NAME, "get_profile"];
        let userId : UserID = Principal.toText(msg.caller);

        switch (canisterProfileIDs.get(userId)) {
            case (null) {
                await Logger.log_event(tags, debug_show(("canisterId_not_found", userId)));
                #err(#CanisterIdNotFound)
            };
            case (?canisterID) {
                let profile = actor (canisterID) : ProfileActor;

                switch (await profile.get_profile(userId)) {
                    case (#err(#ProfileNotFound)) {
                        await Logger.log_event(tags, "profile_not_found");
                        #err(#FailedGetProfile);
                    };
                    case (#ok(profile)) {
                        await Logger.log_event(tags, "profile_returned");
                        #ok(profile);
                    };
                };
            };
        };
    };

    // Canister Management
    private func create_canister() : async () {
        let tags = [ACTOR_NAME, "create_canister"];

        // create canister
        // Cycles.add(1000000000000);
        let profileActor = await Profile.Profile();
        let principal = Principal.fromActor(profileActor);
        let canisterID = Principal.toText(principal);

        // add to canister cache
        let canister : Canister = {
            ID = canisterID;
            creation = Time.now();
            isFull = false;
        };

        canisterCache.put(canisterID, canister);

        // update current empty canister ID
        currentEmptyProfileCanisterID := canisterID;

        await Logger.log_event(tags, debug_show(("canister_created", canisterID)));
    };

    system func heartbeat() : async () {
        let SECONDS_TO_CHECK_CANISTER_FILLED = 60;
        let now = Time.now();
        let elapsedSeconds = (now - anchorTime) / 1000_000_000;

        if (elapsedSeconds > SECONDS_TO_CHECK_CANISTER_FILLED) {
            let tags = [ACTOR_NAME, "heartbeat"];

            anchorTime := now;

            // initialize first canister
            if (currentEmptyProfileCanisterID.size() < 1) {
                await Logger.log_event(tags, debug_show(("first_canister_created")));
                await Logger.log_event(tags, debug_show(("currentEmptyProfileCanisterID", currentEmptyProfileCanisterID)));

                await create_canister();
            };

            // check if current canister is full
            //TODO: test in Prod
            let profile = actor (currentEmptyProfileCanisterID) : ProfileActor;
            let isFull = await profile.is_full();

            if (isFull) {
                await Logger.log_event(tags, "currentEmptyProfileCanisterID_isFull");
                await create_canister();
            };
        }
    };

    system func preupgrade() {
        // usernamesEntries := Iter.toArray(usernames.entries());
        // canisterProfileIDsEntries := Iter.toArray(canisterProfileIDs.entries());
        // canisterCacheEntries := Iter.toArray(canisterCache.entries());
    };

    system func postupgrade() {
        // usernames := HashMap.fromIter<Username, UserID>(usernamesEntries.vals(), 1, Text.equal, Text.hash);
        // usernamesEntries := [];

        // canisterProfileIDs := HashMap.fromIter<UserID, CanisterID>(canisterProfileIDsEntries.vals(), 1, Text.equal, Text.hash);
        // canisterProfileIDsEntries := [];

        // canisterCache := HashMap.fromIter<CanisterID, Canister>(canisterCacheEntries.vals(), 1, Text.equal, Text.hash);
        // canisterCacheEntries := [];
    };
};
