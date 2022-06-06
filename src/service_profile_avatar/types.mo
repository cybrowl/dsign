import Principal "mo:base/Principal";
// import Text "mo:base/Text";

// service_profile_avatar
module {
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
        body : [Nat8];
        headers : [HeaderField];
        status_code : Nat16;
    };

    public type AvatarImgOk = {
        avatar_url: Text;
    };

    public type AvatarImgErr = {
        #AvatarImgTooBig;
        #ImgNotValid;
        #FailedAvatarUrlUpdateProfileNotFound;
    };

    public type Image = {
        content: [Nat8]
    };
}
