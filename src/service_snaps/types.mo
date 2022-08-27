import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

module {
    public type FileAssetUrl = Text;
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Principal;

    // Images
    public type Image = {
        data: Blob
    };
    public type ImageID = Text;
    public type Images = [Image];
    public type ImagesUrls = [ImageUrl];
    public type ImageUrl = Text;

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
        creator: Username;
        image_urls: [Text];
        file_asset_url: FileAssetUrl;
        likes: Nat;
        projects: ?[ProjectRef];
        title: Text;
        views: Nat;
    };

    public type CreateSnapErr = {
        #NoImageToSave;
        #OneImageMax;
        #UsernameNotFound;
        #UserNotFound;
    };

    public type AddImgUrlSnapErr = {
        #ImgLimitReached;
        #UserNotCreator;
        #UsernameNotFound;
        #SnapNotFound;
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

    public type CreateSnapArgs = {
        title: Text;
        cover_image_location: Nat8;
        images: Images;
        file_asset: FileAsset;
    };

    public type FinalizeSnapArgs = {
        canister_id: Text;
        snap_id: SnapID;
        images: Images;
    };

    // Project
    public type ProjectID = Text;

    public type ProjectRef = {
        id: ProjectID;
        name: Text;
    };

    // Actor Interface
    public type SnapActor = actor {
        delete_snaps : shared ([SnapID]) -> async ();
        save_snap : shared (CreateSnapArgs, [ImageID], FileAssetUrl, UserPrincipal) -> async Result.Result<Snap, Text>;
        get_all_snaps : query ([SnapID]) -> async [Snap];
        add_img_url_to_snap : shared (ImageUrl, SnapID, UserPrincipal) -> async Result.Result<Snap, AddImgUrlSnapErr>;
    };

    public type SnapImagesActor = actor {
        save_images : shared (Images) -> async ImagesUrls;
    };
};