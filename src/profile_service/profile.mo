import Debug "mo:base/Debug";

actor Profile {
    public query func ping() : async Text {
        return "meow";
    };
};
