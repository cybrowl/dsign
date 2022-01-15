import Debug "mo:base/Debug";

actor Profile {
    public shared func ping() : async Text {
        return "pong";
    };

    public query func health() : async Text {
        return "good";
    };
};
