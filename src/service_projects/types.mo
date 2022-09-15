import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

module {
    public type Time = Int;
    public type UserPrincipal = Principal;
    public type ProjectCanisterID = Text;
    public type ProjectID = Text;

    public type SnapRef = {
        id: Text;
        canister_id: Text;
    };

    public type Project = {
        id: Text;
        canister_id: Text;
        created: Time;
        username: Text;
        owner: Principal;
        name: Text;
        snaps: ?[SnapRef];
    };

    public type CreateProjectErr = {
        #UserAnonymous;
        #UserNotFound;
        #NotImplemented;
        #ErrorCall: Text;
    };

    // Actor Interface
    public type ProjectActor = actor {
        create_project : shared (Text, ?[SnapRef], UserPrincipal) -> async Result.Result<Project, Text>;
    };
};