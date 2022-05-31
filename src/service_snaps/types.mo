import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

module {
    public type ImageID = Text;
    public type ProjectID = Text;
    public type SnapCanisterID = Text;
    public type SnapImagesCanisterID = Text;
    public type SnapID = Text;
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Text;

    public type CanisterSnap = {
        SnapCanisterID: SnapCanisterID;
        SnapID: SnapID;
    };

    public type CreateSnapArgs = {
        title: Text;
        isPublic: Bool;
        coverImageLocation: Nat8;
        images: Images;
    };

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

    public type ProjectRef = {
        id: ProjectID;
        name: Text;
    };

    public type Snap = {
        id: SnapID;
        coverLocation: Nat8;
        created: Time;
        creator: Username;
        images: [Text];
        isPublic: Bool;
        likes: Nat;
        projects: ?[ProjectRef];
        title: Text;
        views: Nat;
    };

    public type SnapImagesActor = actor {
        add : shared (Images) -> async [ImageID];
    };
};