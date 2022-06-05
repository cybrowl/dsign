import Text "mo:base/Text";

module {
    public func generate_avatar_url(avatarCanisterId: Text, username: Text, isProduction: Bool) : Text {
        var avatar_url = Text.join("", (["https://", avatarCanisterId, ".raw.ic0.app","/avatar/",username].vals()));

        if (isProduction == false) {
           avatar_url := Text.join("", (["http://", avatarCanisterId, ".localhost:8000", "/avatar/", username].vals()));
        };

        return avatar_url;
    };
}