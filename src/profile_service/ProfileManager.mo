import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
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
    type CanisterID = Types.CanisterID;
    type Canister = Types.Canister;
    type UserID = Types.UserID;
    type Username = Types.Username;
    type Profile = Types.Profile;
    type ProfileActor = Types.ProfileActor;
    type ProfileManagerError = Types.ProfileManagerError;

    let ACTOR_NAME : Text = "ProfileManager";

    // User Data Management
    var usernames : HashMap.HashMap<Username, UserID> = HashMap.HashMap(1, Text.equal, Text.hash);
    var canisterIDs : HashMap.HashMap<UserID, CanisterID> = HashMap.HashMap(1, Text.equal, Text.hash);

    // Canister Management
    var anchorTime = Time.now();
    var canisterCache : HashMap.HashMap<CanisterID, Canister> = HashMap.HashMap(1, Text.equal, Text.hash);
    var currentEmptyCanisterID : Text = "";

    public func ping() : async Text {
        return "meow";
    };

    public shared (msg) func create_profile(username: Username) : async Result.Result<Text, ProfileManagerError> {
        // NOTE: this should only be executed once by user
        let tags = [ACTOR_NAME, "create_profile"];
        let userId : UserID = Principal.toText(msg.caller);

        await Logger.log_event(tags, debug_show(("userId", userId)));

        switch (canisterIDs.get(userId)) {
            // check user exists
            case (?canisterID) { #err(#UserIDExists) };
            case (null) {
                // check username available
                switch (usernames.get(username)) {
                    case (?userId) {
                        // await Logger.log_event(tags, "Username Taken");
                        #err(#UsernameTaken)
                    };
                    case (null) {
                        // add username and assign canister id
                        usernames.put(username, userId);
                        canisterIDs.put(userId, currentEmptyCanisterID);

                        // create account in profile
                        await Logger.log_event(tags, debug_show(("before creating profile")));
                        let profile = actor (currentEmptyCanisterID) : ProfileActor;
                        await profile.create(userId, username);
                        await Logger.log_event(tags, debug_show(("after creating profile")));

                        // await Logger.log_event(tags, debug_show(("userId", userId)));

                        #ok("created_profile");
                    };
                };
            };
        };
    };

    public shared (msg) func get_profile() : async Result.Result<Profile, ProfileManagerError> {
        let tags = [ACTOR_NAME, "get_profile"];
        let userId : UserID = Principal.toText(msg.caller);

        switch (canisterIDs.get(userId)) {
            case (null) {
                #err(#CanisterIdNotFound)
            };
            case (?canisterID) {
                let profile = actor (canisterID) : ProfileActor;

                switch (await profile.get_profile(userId)) {
                    case (#err(#ProfileNotFound)) {
                        #err(#FailedGetProfile);
                    };
                    case (#ok(profile)) {
                        // await Logger.log_event(tags, debug_show(("profile", profile)));

                        #ok(profile);
                    };
                };
            };
        };
    };

    private func create_canister() : async () {
        let tags = [ACTOR_NAME, "create_canister"];

        let amount = Cycles.available();
        let balance = Cycles.balance();
        await Logger.log_event(tags, debug_show(("cycles_available", amount)));
        await Logger.log_event(tags, debug_show(("cycles_balance", balance)));

        // create canister
        // FIX: failing to create canister
        Cycles.add(1000000000000);
        let profileActor = await Profile.Profile();
        await Logger.log_event(tags, "created profile actor");

        let principal = Principal.fromActor(profileActor);
        await Logger.log_event(tags, debug_show(("actor_principal", principal)));

        let canisterID = Principal.toText(principal);

        // add to canister cache
        let canister : Canister = {
            ID = canisterID;
            creation = Time.now();
            isFull = false;
        };

        canisterCache.put(canisterID, canister);

        // update current empty canister ID
        currentEmptyCanisterID := canisterID;

        await Logger.log_event(tags, "created!");
        await Logger.log_event(tags, currentEmptyCanisterID);
    };

    system func heartbeat() : async () {
        let SECONDS_TO_CHECK_CANISTER_FILLED = 10;
        let now = Time.now();
        let elapsedSeconds = (now - anchorTime) / 1000_000_000;

        if (elapsedSeconds > SECONDS_TO_CHECK_CANISTER_FILLED) {
            let tags = [ACTOR_NAME, "heartbeat"];

            anchorTime := now;

            // initialize first canister
            if (currentEmptyCanisterID.size() < 1) {
                await Logger.log_event(tags, debug_show(("currentEmptyCanisterID", currentEmptyCanisterID)));

                await create_canister();
            };

            // check if current canister is full
            let profile = actor (currentEmptyCanisterID) : ProfileActor;
            let isFull = await profile.is_full();

            if (isFull) {
                await create_canister();
            };

            await Logger.log_event(tags, "End of Heartbeat");
        }
    };
};
