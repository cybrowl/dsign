import Result "mo:base/Result";

module {
    // Images
    public type ImageID = Text;

    public type Img = {
        data : Blob;
        file_format : Text;
    };

    public type AssetImg = Img and {
        created : Int;
        owner : Principal;
    };

    public type ImageRef = {
        canister_id : Text;
        id : Text;
        url : Text;
    };

    // HTTP
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

    // Actor Interface
    type AssetImgErr = {
        #NotAuthorized;
        #NotOwnerOfAsset;
        #AssetNotFound;
    };
    public type ImageAssetsActor = actor {
        save_images : shared ([Nat], Text, Principal) -> async Result.Result<[ImageRef], AssetImgErr>;
    };
}