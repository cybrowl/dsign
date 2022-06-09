import Text "mo:base/Text";

// service_profile
module {
    public func generate_avatar_url(avatarCanisterId: Text, username: Text, isProduction: Bool) : Text {
        var avatar_url = Text.join("", (["https://", avatarCanisterId, ".raw.ic0.app","/avatar/",username].vals()));

        if (isProduction == false) {
            avatar_url := Text.join("", (["http://127.0.0.1:8000/avatar/", username, "?canisterId=", avatarCanisterId].vals()));
        };

        return avatar_url;
    };
}