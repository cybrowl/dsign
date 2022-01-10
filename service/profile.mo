import Debug "mo:base/Debug";

actor Profile {
    public shared func greet(name : Text) : async Text {
        return "hi, " # name # "!";
    };

    public shared func hey(name : Text) : async Text {
        return "hey, " # name # "!";
    };

    public shared query func hello() : async Text {
      return "Hello";
   };
};
