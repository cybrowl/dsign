import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

module {
    public type Time = Int;
    public type UserID = Text;
    public type Username = Text;
    public type CanisterID = Text;
    public type SnapID = Text;

    public type CanisterSnap = {
        CanisterID: CanisterID;
        SnapID: SnapID;
    };

    public type Project = {
        ID: Text;
        name: Text;
        created: Time;
        isPublic: Bool;
        owners: [Username];
        snaps: [Snap];
    };

    public type ProjectRef = {
        ID: Text;
        name: Text;
    };

    public type Snap = {
        ID: Text;
        created: Time;
        title: Text;
        likes: Nat;
        views: Nat;
        isPublic: Bool;
        owner: Username;
        coverImage: Text;
        images: [Text];
        projects: [ProjectRef];
    };
};