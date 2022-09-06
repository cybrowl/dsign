import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import AssetTypes "../service_assets/types";
import ImgAssetTypes "../service_assets_img/types";

module {
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Principal;

    public type ImageRef = ImgAssetTypes.ImageRef;
    public type ImageAssetsActor = ImgAssetTypes.ImageAssetsActor;

    public type AssetRef = AssetTypes.AssetRef;
    public type AssetsActor = AssetTypes.AssetsActor;
    public type CreateAssetArgs = AssetTypes.CreateAssetArgs;

    // Snap
    public type SnapCanisterID = Text;
    public type SnapID = Text;

    public type Snap = {
        canister_id: Text;
        created: Time;
        file_asset: AssetRef;
        id: SnapID;
        image_cover_location: Nat8;
        images: [ImageRef];
        projects: ?[ProjectRef];
        tags: ?[Text];
        title: Text;
        username: Username;
        metrics: {
            likes: Nat;
            views: Nat;
        };
    };

    public type FileAsset = {
        chunk_ids: [Nat];
        content_type: Text;
        is_public: Bool;
    };

    public type CreateSnapArgs = {
        title: Text;
        image_cover_location: Nat8;
        img_asset_ids: [Nat];
        file_asset: ?FileAsset;
    };

    public type CreateSnapErr = {
        #UserAnonymous;
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

    // Project
    public type ProjectID = Text;

    public type ProjectRef = {
        id: ProjectID;
        name: Text;
    };

    // Actor Interface
    public type SnapActor = actor {
        create_snap : shared (CreateSnapArgs, [ImageRef], AssetRef, UserPrincipal) -> async Result.Result<Snap, Text>;
        delete_snaps : shared ([SnapID]) -> async ();
        get_all_snaps : query ([SnapID]) -> async [Snap];
    };
};