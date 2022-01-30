import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Prim "mo:⛔";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Time "mo:base/Time";

import Logger "canister:logger";
import Profile "profile";
import Types "./types";

actor ProfileManager {
    type CanisterID = Types.CanisterID;
    type Canister = Types.Canister;
    type UserID = Types.UserID;
    type Username = Types.Username;
    type Profile = Types.Profile;
    type ProfileActor = Types.ProfileActor;

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

    public shared (msg) func create_profile(username: Username) : async () {
        // NOTE: this should only be executed once by user
        let tags = ["ProfileManager", "create_profile"];
        let userId : UserID = Principal.toText(msg.caller);

        // TODO: return success/fail messages

        // check user doesn't have an account
        switch (canisterIDs.get(userId)) {
            case (?id) { await Logger.log_event(tags, "Warning: UserID exists"); };
            case (null) { await Logger.log_event(tags, "UserID Null");};
        };

        // check username available
        switch (usernames.get(username)) {
            case (?id) { await Logger.log_event(tags, "Warning: username taken"); };
            case (null) {
                // add username
                usernames.put(username, userId);

                // link username + userID to canisterID
                canisterIDs.put(userId, currentEmptyCanisterID);

                // call profile.create(UserID)
                let profile = actor (currentEmptyCanisterID) : ProfileActor;

                await profile.create(userId, username);

                await Logger.log_event(tags, "created!");
            };
        };
    };

    private func create_canister() : async () {
        let tags = [ACTOR_NAME, "create_canister"];

        // create canister
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
        currentEmptyCanisterID := canisterID;

        await Logger.log_event(tags, "created!");
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
                await Logger.log_event(tags, "genesis of currentEmptyCanisterID assignment");

                await create_canister();
            };

            // check if current canister is full
            let profile = actor (currentEmptyCanisterID) : ProfileActor;
            let isFull = await profile.is_full();

            if (isFull) {
                await create_canister();
            };

            await Logger.log_event(tags, "the end!");
        }
    };
};
