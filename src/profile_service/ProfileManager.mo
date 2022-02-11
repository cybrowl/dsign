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
    type Canister = Types.Canister;
    type CanisterID = Types.CanisterID;
    type Profile = Types.Profile;
    type ProfileActor = Types.ProfileActor;
    type ProfileManagerError = Types.ProfileManagerError;
    type User = Types.User;
    type UserID = Types.UserID;
    type Username = Types.Username;

    let ACTOR_NAME : Text = "ProfileManager";

    // User Data Management
    var usernames : HashMap.HashMap<Username, User> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var usernamesEntries : [(Username, User)] = [];

    var canisterIDs : HashMap.HashMap<UserID, CanisterID> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var canisterIDsEntries : [(UserID, CanisterID)] = [];

    // Canister Management
    stable var anchorTime = Time.now();
    stable var currentEmptyCanisterID : Text = "";

    var canisterCache : HashMap.HashMap<CanisterID, Canister> = HashMap.HashMap(1, Text.equal, Text.hash);
    stable var canisterCacheEntries : [(CanisterID, Canister)] = [];

    public func ping() : async Text {
        return "meow";
    };

    // User Data Management
    public query (msg) func has_account() : async Bool  {
        let userId : UserID = Principal.toText(msg.caller);

        switch (canisterIDs.get(userId)) {
            // check user exists
            case (?canisterID) {
                return true;
            };
            case(_) { return false };
        };
    };

    public shared (msg) func create_profile(username: Username) : async Result.Result<Text, ProfileManagerError> {
        // NOTE: this should only be executed once by user
        let tags = [ACTOR_NAME, "create_profile"];
        let userId : UserID = Principal.toText(msg.caller);

        switch (canisterIDs.get(userId)) {
            // check user exists
            case (?canisterID) {
                await Logger.log_event(tags, "userId_exists");
                #err(#UserIDExists)
            };
            case (null) {
                // check username available
                switch (usernames.get(username)) {
                    case (?user) {
                        await Logger.log_event(tags, "username_taken");
                        #err(#UsernameTaken)
                    };
                    case (null) {
                        let user : User = {ID = userId; username = username};
                        // add username and assign canister id
                        usernames.put(username, user);
                        canisterIDs.put(userId, currentEmptyCanisterID);

                        // create account in profile
                        let profile = actor (currentEmptyCanisterID) : ProfileActor;
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

        switch (canisterIDs.get(userId)) {
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
        currentEmptyCanisterID := canisterID;

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
            if (currentEmptyCanisterID.size() < 1) {
                await Logger.log_event(tags, debug_show(("first_canister_created")));
                await Logger.log_event(tags, debug_show(("currentEmptyCanisterID", currentEmptyCanisterID)));

                await create_canister();
            };

            // check if current canister is full
            //TODO: test in Prod
            let profile = actor (currentEmptyCanisterID) : ProfileActor;
            let isFull = await profile.is_full();

            if (isFull) {
                await Logger.log_event(tags, "currentEmptyCanisterID_isFull");
                await create_canister();
            };
        }
    };

    system func preupgrade() {
        usernamesEntries := Iter.toArray(usernames.entries());
        canisterIDsEntries := Iter.toArray(canisterIDs.entries());
        canisterCacheEntries := Iter.toArray(canisterCache.entries());

    };

    system func postupgrade() {
        usernames := HashMap.fromIter<Username, User>(usernamesEntries.vals(), 1, Text.equal, Text.hash);
        usernamesEntries := [];

        canisterIDs := HashMap.fromIter<UserID, CanisterID>(canisterIDsEntries.vals(), 1, Text.equal, Text.hash);
        canisterIDsEntries := [];

        canisterCache := HashMap.fromIter<CanisterID, Canister>(canisterCacheEntries.vals(), 1, Text.equal, Text.hash);
        canisterCacheEntries := [];
    };
};
