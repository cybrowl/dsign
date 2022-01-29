import Int "mo:base/Int";
import Text "mo:base/Text";

module {
    public type Time = Int;

    public type UserID = Text;
    public type Username = Text;
    public type CanisterID = Text;

    public type Tags = [Text];

    public type Canister = {
        ID: CanisterID;
        creation: Time;
        fillRatio: Nat8;
        isFull: Bool
    };

    public type Profile = {
        username: Username;
        specialtyFields: ?Tags;
        created: Time;
        website: ?Text;
    };
};

