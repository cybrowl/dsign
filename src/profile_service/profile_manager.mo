import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Logger "canister:logger";
import Types "./types";

actor ProfileManager {
    type CanisterID = Types.CanisterID;
    type Canister = Types.Canister;
    type UserID = Types.UserID;
    type Username = Types.Username;
    type Profile = Types.Profile;

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
                usernames.put(username, userId);
                canisterIDs.put(userId, currentEmptyCanisterID);

                // check if added properly

                // call profile.create(UserID) & check
            };
        };

    };

    system func heartbeat() : async () {
        let tags = ["ProfileManager", "heartbeat"];

        let SECONDS_TO_CHECK_CANISTER_FILLED = 60;
        let now = Time.now();
        let elapsedSeconds = (now - anchorTime) / 1000_000_000;

        if (elapsedSeconds > SECONDS_TO_CHECK_CANISTER_FILLED) {
            anchorTime := now;

            // if currentEmptyCanisterID is empty (only once for genesis)
            // create new canister 
            // add to canisterCache
            // update currentEmptyCanisterID

            // if currentEmptyCanisterID is full
            // create new canister
            // add to canisterCache
            // update currentEmptyCanisterID

            await Logger.log_event(tags, debug_show(elapsedSeconds));
            await Logger.log_event(tags, "hello");
            await Logger.log_event(tags, "");
        }
    };
};
