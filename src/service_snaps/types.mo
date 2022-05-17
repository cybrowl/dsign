import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

module {
    public type ImageID = Text;
    public type SnapID = Text;
    public type SnapStorageCanisterID = Text;
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Text;

    public type Image = [Nat8];
    public type Images = [Image];

    public type HeaderField = (Text, Text);

    public type HttpRequest = {
        url : Text;
        method : Text;
        headers : [HeaderField];
    };

    public type HttpResponse = {
        body : [Nat8];
        headers : [HeaderField];
        status_code : Nat16;
    };

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