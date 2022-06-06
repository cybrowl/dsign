import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Logger "canister:logger";

import Types "./types";
import Utils "./utils";

actor class Username() = {
    type Username = Types.Username;
    type UsernameError =  Types.UsernameError;
    type UserPrincipal =  Types.UserPrincipal;

    let ACTOR_NAME : Text = "Username";

    var username_owners : HashMap.HashMap<Username, UserPrincipal> = HashMap.HashMap(0, Text.equal, Text.hash);
    stable var username_owners_stable_storage : [(Username, UserPrincipal)] = [];

    var usernames : HashMap.HashMap<UserPrincipal, Username> = HashMap.HashMap(0, Principal.equal, Principal.hash);
    stable var usernames_stable_storage : [(UserPrincipal, Username)] = [];

    // ------------------------- Private Methods -------------------------
    private func check_username_is_available(username: Username) : Bool {
        switch (username_owners.get(username)) {
            case (?owner) {
                return false;
            };
            case(_) {
                return true;
            };
        };  
    };

    private func check_user_has_a_username(caller: UserPrincipal) : Bool {
        switch (usernames.get(caller)) {
            case (?username) {
                return true;
            };
            case(_) {
                return false;
            };
        };
    };

    private func get_current_username(caller: UserPrincipal) : Username {
        switch (usernames.get(caller)) {
            case (?current_username) {
                return current_username;
            };
            case(_) {
                return "";
            };
        };
    };

    // ------------------------- Public Methods -------------------------
    public query func version() : async Text {
        return "0.0.1";
    };

    public query ({caller}) func get_username() : async Result.Result<Username, UsernameError> {
        switch (usernames.get(caller)) {
            case (?username) {
                #ok(username);
            };
            case(_) {
                #err(#UserNotFound)
            };
        };
    };

    public shared ({caller}) func create_username(username: Username) : async Result.Result<Username, UsernameError> {
        let tags = [ACTOR_NAME, "create_username"];
        let is_anonymous = Principal.isAnonymous(caller);

        let valid_username : Bool = Utils.is_valid_username(username);
        let username_available : Bool = check_username_is_available(username);
        let user_has_username: Bool = check_user_has_a_username(caller);

        if (is_anonymous == true) {
            return #err(#UserAnonymous);
        };

        if (valid_username == false) {
            return #err(#UsernameInvalid);
        };

        if (username_available == false) {
            return #err(#UsernameTaken);
        };

        if (user_has_username == true) {
            return #err(#UserHasUsername);
        } else {
            usernames.put(caller, username);
            username_owners.put(username, caller);

            await Logger.log_event(tags, "created");

            //TODO: call create_profile(principal: UserPrincipal, username: Username)

            return #ok(username);
        };
    };

    public shared ({caller}) func update_username(username: Username) : async Result.Result<Username, UsernameError> {
        let tags = [ACTOR_NAME, "update_username"];
        let is_anonymous = Principal.isAnonymous(caller);

        let valid_username : Bool = Utils.is_valid_username(username);
        let username_available : Bool = check_username_is_available(username);
        let user_has_username: Bool = check_user_has_a_username(caller);

        if (is_anonymous == true) {
            return #err(#UserAnonymous);
        };

        if (valid_username == false) {
            return #err(#UsernameInvalid);
        };

        if (username_available == false) {
            return #err(#UsernameTaken);
        } else {
            let current_username: Username = get_current_username(caller);
            username_owners.delete(current_username);
            username_owners.put(username, caller);
            usernames.put(caller, username);

            await Logger.log_event(tags, "updated");

            //TODO: update username in snaps, profile, avatar_url

            return #ok(username);
        };
    };

    // ------------------------- System Methods -------------------------
    system func preupgrade() {
        username_owners_stable_storage := Iter.toArray(username_owners.entries());
        usernames_stable_storage := Iter.toArray(usernames.entries());
    };

    system func postupgrade() {
        // owners
        username_owners := HashMap.fromIter<Username, UserPrincipal>(username_owners_stable_storage.vals(), 0, Text.equal, Text.hash);
        username_owners_stable_storage := [];

        // usernames
        usernames := HashMap.fromIter<UserPrincipal, Username>(usernames_stable_storage.vals(), 0, Principal.equal, Principal.hash);
        usernames_stable_storage := [];
    };
};