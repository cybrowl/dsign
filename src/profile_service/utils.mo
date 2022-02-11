import Text "mo:base/Text";
import Iter "mo:base/Iter";

module {
    public func get_username(url: Text): Text {
        let urlSplitByParams : [Text] = Iter.toArray(Text.tokens(url, #char '?'));
        let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(urlSplitByParams[0], #char '/'));
        let username : Text = urlSplitByPath[urlSplitByPath.size() - 1];

        if (urlSplitByParams.size() == 0) {
            return ""
        };

        return username;
    };
}