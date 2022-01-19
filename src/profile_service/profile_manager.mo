import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

actor ProfileManager {
    public query func ping() : async Text {
        return "meow";
    };

    public shared query (message) func get_canister_caller_principal() : async Text {
        return Principal.toText(message.caller);
    };
};
