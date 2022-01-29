import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Logger "canister:logger";

import Types "./types";

actor ProfileManager {
    type CanisterID = Types.CanisterID;
    type Canister = Types.Canister;
    type UserID = Types.UserID;
    type Username = Types.Username;

    // User Data Management
    var usernames : HashMap.HashMap<Username, UserID> = HashMap.HashMap(1, Text.equal, Text.hash);
    var canisterIDs : HashMap.HashMap<UserID, CanisterID> = HashMap.HashMap(1, Text.equal, Text.hash);

    // Canister Management
    // var canisterCache : HashMap.HashMap<CanisterID, Canister> = HashMap.HashMap(1, Text.equal, Text.hash);
    var anchorTime = Time.now();

    public func ping() : async Text {
        return "meow";
    };

    public shared (msg) func set_username(username: Username) : async () {
        let canisterId : CanisterID = "canister-id";
        let userId : UserID = Principal.toText(msg.caller);

        usernames.put(username, userId);
        canisterIDs.put(userId, canisterId);
    };

    // Get Canister
    public shared (msg) func get_canister(username: Username) : async CanisterID {
        var userId : UserID = "";
        var canisterId : CanisterID = "";

        switch (usernames.get(username)) {
            case (null) { Debug.print("error") };
            case (?id) { userId := id };
        };

        switch (canisterIDs.get(userId)) {
            case (null) { Debug.print("error") };
            case (?id) { canisterId := id };
        };

        return canisterId;
    };

    system func heartbeat() : async () {
        let tags = ["ProfileManager", "heartbeat"];

        let SECONDS_TO_CHECK_CANISTER_FILLED = 60;
        let now = Time.now();
        let elapsedSeconds = (now - anchorTime) / 1000_000_000;

        if (elapsedSeconds > SECONDS_TO_CHECK_CANISTER_FILLED) {
            anchorTime := now;

            await Logger.log_event(tags, debug_show(elapsedSeconds));
            await Logger.log_event(tags, "hello");
            await Logger.log_event(tags, "");
        }
    };

    //TODO: get profile
    //TODO: create profile
    //TODO: update profile
    //TODO: remove profile
    //TODO: update username
        // if update username -> check if username exists, remove username from usernames, add new username
};
