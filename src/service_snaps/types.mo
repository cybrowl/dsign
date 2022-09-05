import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

module {
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Principal;

    public type AssetRef = {
        asset_url : Text;
        canister_id : Text;
        id : Text;
    };

    // Images
    public type ImageRef = {
        canister_id : Text;
        id : Text;
        url : Text;
    };

    public type HeaderField = (Text, Text);

    public type HttpRequest = {
        url : Text;
        method : Text;
        headers : [HeaderField];
    };

    public type HttpResponse = {
        body : Blob;
        headers : [HeaderField];
        status_code : Nat16;
    };

    // Snap
    public type SnapCanisterID = Text;
    public type SnapID = Text;
    public type SnapImagesCanisterID = Text;

    public type Snap = {
        id: SnapID;
        canister_id: Text;
        cover_image_location: Nat8;
        created: Time;
        username: Username;
        images: [ImageRef];
        file_asset: AssetRef;
        projects: ?[ProjectRef];
        title: Text;
        likes: Nat;
        views: Nat;
    };

    public type CreateSnapArgs = {
        title: Text;
        cover_image_location: Nat8;
        img_asset_ids: [Nat];
        file_asset: ?FileAsset;
    };

    public type CreateSnapErr = {
        #NoImageToSave;
        #FourImagesMax;
        #UsernameNotFound;
        #UserNotFound;
        #ErrorCall: Text;
    };

   public type GetAllSnapsErr = {
        #UserNotFound;
    };

    public type DeleteAllSnapsErr = {
        #UserNotFound;
    };

    public type FileAsset = {
        chunk_ids: [Nat];
        content_type: Text;
        is_public: Bool;
    };

    // Project
    public type ProjectID = Text;

    public type ProjectRef = {
        id: ProjectID;
        name: Text;
    };

    // Actor Interface
    public type SnapActor = actor {
        save_snap : shared (CreateSnapArgs, [ImageRef], AssetRef, UserPrincipal) -> async Result.Result<Snap, Text>;
        delete_snaps : shared ([SnapID]) -> async ();
        get_all_snaps : query ([SnapID]) -> async [Snap];
    };

    type AssetImgErr = {
        #NotAuthorized;
        #NotOwnerOfAsset;
        #AssetNotFound;
    };
    public type ImageAssetsActor = actor {
        save_images : shared ([Nat], Text, Principal) -> async Result.Result<[ImageRef], AssetImgErr>;
    };
};