import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";

actor Profile = {
    public query func ping() : async Text {
        return "meow";
    };

    public shared query (message) func get_canister_caller_principal() : async Hash.Hash {
        return Principal.hash(message.caller);
    };
};
