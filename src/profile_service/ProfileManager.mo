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

import Avatar "Avatar";
import Logger "canister:logger";
import Profile "Profile";
import Types "./types";
import Utils "./utils";

actor ProfileManager {
    type AvatarActor = Types.AvatarActor;
    type Canister = Types.Canister;
    type CanisterID = Types.CanisterID;
    type Image = Types.Image;
    type Profile = Types.Profile;
    type ProfileActor = Types.ProfileActor;
    type ProfileManagerError = Types.ProfileManagerError;
    type ProfileManagerOk = Types.ProfileManagerOk;
    type UserID = Types.UserID;
    type Username = Types.Username;

    let ACTOR_NAME : Text = "ProfileManager";
    let cycleAmount : Nat = 1_000_000_000_000;

    // User Data Management
    var userIds : HashMap.HashMap<Username, UserID> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var userIdsEntries : [(Username, UserID)] = [];

    var usernames : HashMap.HashMap<UserID, Username> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var usernamesEntries : [(UserID, Username)] = [];

    var canisterProfileIds : HashMap.HashMap<UserID, CanisterID> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var canisterProfileIdsEntries : [(UserID, CanisterID)] = [];

    var canisterAvatarIds : HashMap.HashMap<UserID, CanisterID> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var canisterAvatarIdsEntries : [(UserID, CanisterID)] = [];

    // Canister Data Management
    stable var anchorTime = Time.now();
    stable var currentEmptyAvatarCanisterID : Text = "renrk-eyaaa-aaaaa-aaada-cai";
    stable var currentEmptyProfileCanisterID : Text = "rno2w-sqaaa-aaaaa-aaacq-cai";

    var canisterCache : HashMap.HashMap<CanisterID, Canister> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var canisterCacheEntries : [(CanisterID, Canister)] = [];

    // Canister Logic Utils
    public func version() : async Text {
        return "0.0.6";
    };

    public shared (msg) func whoami() : async Principal {
        return msg.caller;
    };

    // User Logic Management
    public query (msg) func has_account() : async Bool  {
        let userId : UserID = Principal.toText(msg.caller);

        switch (canisterProfileIds.get(userId)) {
            // check user exists
            case (?canisterID) {
                return true;
            };
            case(_) { return false };
        };
    };

    public shared (msg) func set_avatar(avatar: Image) : async Result.Result<ProfileManagerOk, ProfileManagerError> {
        let tags = [ACTOR_NAME, "set_avatar"];
        let userId : UserID = Principal.toText(msg.caller);

        switch (usernames.get(userId)) {
            case (?username) {
                // save to get avatar canister id with userId
                canisterAvatarIds.put(userId, currentEmptyAvatarCanisterID);

                // call avatar canister and set avatar
                let avatarActor = actor (currentEmptyAvatarCanisterID) : AvatarActor;
                let isAvatarSet : Bool = await avatarActor.set(avatar, username);

                if (isAvatarSet) {
                    // call profile canister and set avatar URL
                    let profileActor = actor (currentEmptyProfileCanisterID) : ProfileActor;
                    await profileActor.set_avatar(userId, username);

                    await Logger.log_event(tags, "AvatarCreated");
                    #ok(#AvatarCreated);
                } else {
                    await Logger.log_event(tags, "AvatarSetFailed");

                    #err(#AvatarSetFailed);
                }
            };
            case (null) {
                await Logger.log_event(tags, "UsernameNotFound");
                #err(#UsernameNotFound)
            };
        };
    };

    public shared (msg) func create_profile(username: Username) : async Result.Result<ProfileManagerOk, ProfileManagerError> {
        // NOTE: this should only be executed once by user
        let tags = [ACTOR_NAME, "create_profile"];
        let userId : UserID = Principal.toText(msg.caller);

        let isValidUsername : Bool = Utils.is_valid_username(username);

        if (isValidUsername == false) {
            #err(#UsernameInvalid);
        } else {
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
                    canisterProfileIds.put(userId, currentEmptyProfileCanisterID);

                    // create username in profile
                    let profile = actor (currentEmptyProfileCanisterID) : ProfileActor;
                    await profile.create(userId, username);

                    await Logger.log_event(tags, "profile_created");
                    #ok(#ProfileCreated);
                };
            };
        };
    };

    public shared (msg) func get_profile() : async Result.Result<Profile, ProfileManagerError> {
        let tags = [ACTOR_NAME, "get_profile"];
        let userId : UserID = Principal.toText(msg.caller);

        switch (canisterProfileIds.get(userId)) {
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

    // Canister Logic Management
    private func create_avatar_canister() : async () {
        let tags = [ACTOR_NAME, "create_avatar_canister"];

        // create canister
        Cycles.add(cycleAmount);
        let avatarActor = await Avatar.Avatar();
        let principal = Principal.fromActor(avatarActor);
        let canisterID = Principal.toText(principal);

        // add to canister cache
        let canister : Canister = {
            ID = canisterID;
            creation = Time.now();
            isFull = false;
        };

        canisterCache.put(canisterID, canister);

        // update current empty canister ID
        currentEmptyAvatarCanisterID := canisterID;

        await Logger.log_event(tags, debug_show(("avatar_canister_created", canisterID)));
    };

    private func create_profile_canister() : async () {
        let tags = [ACTOR_NAME, "create_profile_canister"];
        let profileManagerPrincipal =  await whoami();
        let profileManagerPrincipalText = Principal.toText(profileManagerPrincipal);

        // create canister
        Cycles.add(cycleAmount);
        let profileActor = await Profile.Profile(profileManagerPrincipalText, currentEmptyAvatarCanisterID);
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

        await Logger.log_event(tags, debug_show(("profile_canister_created", canisterID)));
    };

    public shared (msg) func heart_beat() : async ()  {
        let tags = [ACTOR_NAME, "heartbeat"];

        // initialize first avatar canister
        if (currentEmptyAvatarCanisterID.size() < 1) {
            await Logger.log_event(tags, debug_show(("Initialize: currentEmptyAvatarCanisterID", currentEmptyAvatarCanisterID)));

            await create_avatar_canister();
        };

        // initialize first profile canister
        if (currentEmptyProfileCanisterID.size() < 1) {
            await Logger.log_event(tags, debug_show(("Initialize: currentEmptyProfileCanisterID", currentEmptyProfileCanisterID)));

            await create_profile_canister();
        };

        // check if avatar canister is full
        //TODO: test in Prod
        let avatarActor = actor (currentEmptyAvatarCanisterID) : AvatarActor;
        let isAvatarCanisterFull = await avatarActor.is_full();

        if (isAvatarCanisterFull) {
            await Logger.log_event(tags, "avatar_canister_is_full");
            await create_avatar_canister();
        };

        // check if profile canister is full
        //TODO: test in Prod
        let profileActor = actor (currentEmptyProfileCanisterID) : ProfileActor;
        let isProfileCanisterFull = await profileActor.is_full();

        if (isProfileCanisterFull) {
            await Logger.log_event(tags, "profile_canister_is_full");
            await create_profile_canister();
        };

         await Logger.log_event(tags, debug_show(("End: currentEmptyAvatarCanisterID", currentEmptyAvatarCanisterID)));
         await Logger.log_event(tags, debug_show(("End: currentEmptyProfileCanisterID", currentEmptyProfileCanisterID)));
    };

    system func preupgrade() {
        userIdsEntries := Iter.toArray(userIds.entries());
        usernamesEntries := Iter.toArray(usernames.entries());
        canisterProfileIdsEntries := Iter.toArray(canisterProfileIds.entries());
        canisterAvatarIdsEntries := Iter.toArray(canisterAvatarIds.entries());
        canisterCacheEntries := Iter.toArray(canisterCache.entries());
    };

    system func postupgrade() {
        userIds := HashMap.fromIter<Username, UserID>(userIdsEntries.vals(), 1, Text.equal, Text.hash);
        userIdsEntries := [];

        usernames := HashMap.fromIter<UserID, Username>(usernamesEntries.vals(), 1, Text.equal, Text.hash);
        usernamesEntries := [];

        canisterAvatarIds := HashMap.fromIter<UserID, CanisterID>(canisterAvatarIdsEntries.vals(), 1, Text.equal, Text.hash);
        canisterAvatarIdsEntries := [];

        canisterProfileIds := HashMap.fromIter<UserID, CanisterID>(canisterProfileIdsEntries.vals(), 1, Text.equal, Text.hash);
        canisterProfileIdsEntries := [];

        canisterCache := HashMap.fromIter<CanisterID, Canister>(canisterCacheEntries.vals(), 1, Text.equal, Text.hash);
        canisterCacheEntries := [];
    };
};
