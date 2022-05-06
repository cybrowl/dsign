import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

module {
    public type Time = Int;
    public type UserPrincipal = Text;
    public type Username = Text;
    public type SnapStorageCanisterID = Text;
    public type SnapID = Text;

    public type CanisterSnap = {
        SnapStorageCanisterID: SnapStorageCanisterID;
        SnapID: SnapID;
    };

    public type ProjectRef = {
        ID: Text;
        name: Text;
    };

    public type Snap = {
        ID: Text;
        coverImage: Text;
        created: Time;
        creator: Username;
        images: [Text];
        isPublic: Bool;
        likes: Nat;
        projects: [ProjectRef];
        title: Text;
        views: Nat;
    };
};