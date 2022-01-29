import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Logger "canister:logger";

import Types "./types";
import TypesLog "../logger/types"

actor ProfileManager {
    type CanisterID = Types.CanisterID;
    type Canister = Types.Canister;
    type UserID = Types.UserID;
    type Username = Types.Username;
    type Log = TypesLog.Log;

    // User Data Management
    var usernames : HashMap.HashMap<Username, UserID> = HashMap.HashMap(1, Text.equal, Text.hash);
    var canisterIDs : HashMap.HashMap<UserID, CanisterID> = HashMap.HashMap(1, Text.equal, Text.hash);

    // Canister Management
    // var canisterCache : HashMap.HashMap<CanisterID, Canister> = HashMap.HashMap(1, Text.equal, Text.hash);

    public func ping() : async Text {
        let log : Log = { time = 234234234231; tags = ["method", "ping"]; payload = "works!" };

        await Logger.log_event(log);

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

    //TODO: get profile

    //TODO: create profile
    //TODO: update profile
    //TODO: remove profile
    //TODO: update username
        // if update username -> check if username exists, remove username from usernames, add new username

    //TODO: 
};
