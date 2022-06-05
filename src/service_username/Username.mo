import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

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

    public shared ({caller}) func save_username(username: Username) : async Result.Result<Username, UsernameError> {
        let principal : UserPrincipal = Principal.toText(caller);

        //TODO check identity is not ANON

        let valid_username : Bool = Utils.is_valid_username(username);

        if (valid_username == false) {
            #err(#UsernameInvalid);
        } else {
            switch (username_owners.get(username)) {
                case (?username) {
                    #err(#UsernameTaken);
                };
                case(_) {
                    usernames.put(principal, username);
                    username_owners.put(username, principal);

                    //TODO: update profile with correct username
                    #ok(username);
                };
            };
        };
    };
};
