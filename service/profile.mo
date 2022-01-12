import Debug "mo:base/Debug";

actor Profile {
    public shared func greet(name : Text) : async Text {
        return "hi, " # name # "!";
    };
};
