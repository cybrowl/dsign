module {
    public type Img = {
        data : Blob;
        file_format : Text;
    };

    public type AssetImg = Img and {
        created : Int;
        owner : Principal;
    };
}