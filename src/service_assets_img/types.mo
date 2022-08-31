module {
    // Images
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
    public type ImageID = Text;
    public type ImagesRef = [ImageRef];

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
}