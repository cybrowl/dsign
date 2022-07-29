import Principal "mo:base/Principal";
import Result "mo:base/Result";
// import Text "mo:base/Text";

// service_profile_avatar
module {
    public type ProfileAvatarImagesCanisterId = Text;
    public type Time = Int;
    public type Username = Text;
    public type UserPrincipal = Principal;

    public type HeaderField = (Text, Text);

    public type HttpRequest = {
        url : Text;
        method : Text;
        body : [Nat8];
        headers : [HeaderField];
    };

    public type HttpResponse = {
        body : Blob;
        headers : [HeaderField];
        status_code : Nat16;
    };

    public type AvatarImgOk = {
        avatar_url: Text;
    };

    public type AvatarImgErr = {
        #AvatarImgTooBig;
        #ImgNotValid;
        #FailedGetUsername;
        #FailedSaveAvatarImg;
        #FailedAvatarUrlUpdateProfileNotFound;
    };

    public type Image = {
        data: Blob
    };

    // Actor Interface
    public type ProfileAvatarImagesActor = actor {
        save_image : shared (avatar: Image, caller: UserPrincipal) -> async Result.Result<AvatarImgOk, AvatarImgErr>;
    };
}
