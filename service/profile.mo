import Debug "mo:base/Debug";

actor Profile {
    public shared func ping() : async Text {
        return "pong";
    };

    // public shared func canisterSize() : async Nat64 {
    //     return StableMemory.size();
    // }
};
