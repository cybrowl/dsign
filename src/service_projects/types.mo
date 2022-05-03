import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

module {
    public type CanisterProjectID = Text;
    public type ProjectID = Text;
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Text;

    public type CanisterProject = {
        CanisterProjectID: CanisterProjectID;
        ProjectID: ProjectID;
    };

    public type SnapRef = {
        ID: Text;
        title: Text;
    };

    public type Project = {
        ID: Text;
        created: Time;
        creator: Username;
        isPublic: Bool;
        name: Text;
        snaps: [SnapRef];
    };
};