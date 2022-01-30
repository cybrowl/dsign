import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
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
        isFull: Bool
    };

    public type Profile = {
        username: Username;
        created: Time;
        website: Text;
    };

    public type ProfileManagerError = { #CanisterIdNotFound; #UsernameTaken; #UsernameExists; #FailedGetProfile; };
    public type ProfileError = { #NotFound; };

    public type ProfileActor = actor {
        ping : query () -> async Text;
        is_full : query () -> async Bool;
        create : shared (Text, Text) -> async ();
        get_profile : query (UserID) -> async Result.Result<Profile, ProfileError>;
    };
};

