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
        avatar: Text;
        created: Time;
        username: Username;
        website: Text;
    };

    public type Image = {
        content: [Nat8]
    };

    public type HeaderField = (Text, Text);

    public type HttpRequest = {
        url : Text;
        method : Text;
        body : [Nat8];
        headers : [HeaderField];
    };

    public type HttpResponse = {
        body : [Nat8];
        headers : [HeaderField];
        status_code : Nat16;
    };

    public type AvatarError = {
        #UsernameNotFound;
        #SetAvatarFailed;
    };

    public type ProfileManagerError = {
        #CanisterIdNotFound;
        #FailedGetProfile;
        #UserIDExists;
        #UsernameTaken;
    };

    public type ProfileError = { #ProfileNotFound; };

    public type AvatarActor = actor {
        ping : query () -> async Text;
        is_full : query () -> async Bool;
        set : shared (Image, Username) -> async Bool;
        http_request : shared query HttpRequest -> async HttpResponse;
    };

    public type ProfileActor = actor {
        ping : query () -> async Text;
        is_full : query () -> async Bool;
        create : shared (Text, Text) -> async ();
        set_avatar : shared (Text, Text) -> async ();
        get_profile : query (UserID) -> async Result.Result<Profile, ProfileError>;
    };
};

