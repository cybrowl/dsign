import Int "mo:base/Int";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

module {
    public type Time = Int;

    public type UserID = Text;
    public type Username = Text;
    public type CanisterID = Text;

    public type Tags = [Text];

    public type Canister = {
        ID: CanisterID;
        creation: Time;
        isFull: Bool
    };

    public type Profile = {
        username: Username;
        specialtyFields: [Tags];
        created: Time;
        website: Text;
    };

    public type ProfileActor = actor {
        ping : query () -> async Text;
        is_full : query () -> async Bool;
        create : shared (Text, Text) -> async ();
    };
};

