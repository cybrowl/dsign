import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
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
    // stable var username_owners_entries : [(Username, UserPrincipal)] = [];
    var usernames : HashMap.HashMap<UserPrincipal, Username> = HashMap.HashMap(0, Text.equal, Text.hash);
    // stable var usernames_entries : [(UserPrincipal, Username)] = [];

    public query func version() : async Text {
        return "0.0.1";
    };

    public query ({caller}) func get_username() : async Result.Result<Username, UsernameError> {
        let principal : UserPrincipal = Principal.toText(caller);

        switch (usernames.get(principal)) {
            case (?username) {
                #ok(username);
            };
            case(_) {
                #err(#UserNotFound)
            };
        };
    };

    private func check_username_is_available(username: Username): Bool {
        switch (username_owners.get(username)) {
            case (?owner) {
                return false;
            };
            case(_) {
                return true;
            };
        };  
    };

    private func check_user_has_a_username(principal: UserPrincipal): Bool {
        switch (usernames.get(principal)) {
            case (?username) {
                return true;
            };
            case(_) {
                return false;
            };
        };
    };

    public shared ({caller}) func create_username(username: Username) : async Result.Result<Username, UsernameError> {
        let tags = [ACTOR_NAME, "create_username"];
        let principal : UserPrincipal = Principal.toText(caller);

        //TODO check identity is not ANON

        let valid_username : Bool = Utils.is_valid_username(username);
        let username_available : Bool = check_username_is_available(username);
        let has_username: Bool = check_user_has_a_username(principal);
    
        if (valid_username == false) {
            #err(#UsernameInvalid);
        } else {
            if (username_available == false) {
                #err(#UsernameTaken);
            } else {
                if (has_username == true) {
                    #err(#UserHasUsername);
                } else {
                    usernames.put(principal, username);
                    username_owners.put(username, principal);

                    await Logger.log_event(tags, debug_show("created"));

                    //TODO: update profile with correct username
                    #ok(username);
                };
            };
        };
    };

    // public shared ({caller}) func update_username(username: Username) : async Result.Result<Username, UsernameError> {
    //     let tags = [ACTOR_NAME, "update_username"];
    //     let principal : UserPrincipal = Principal.toText(caller);

    //     //TODO check identity is not ANON

    //     // does anyone own the username
    //     // 

    //     let valid_username : Bool = Utils.is_valid_username(username);

    //     if (valid_username == false) {
    //         #err(#UsernameInvalid);
    //     } else {
    //         switch (usernames.get(principal)) {
    //             case (?username_) {
    //                 if (username_ == principal) {
                        

    //                     #ok(username);
    //                 } else {
    //                     #err(#UsernameTaken);
    //                 };
    //             };
    //             case(_) {
    //                 usernames.put(principal, username);
    //                 username_owners.put(username, principal);

    //                 await Logger.log_event(tags, debug_show("created username"));

    //                 //TODO: update profile with correct username
    //                 #ok(username);
    //             };
    //         };
    //     };
    // };
};