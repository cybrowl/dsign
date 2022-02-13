import Text "mo:base/Text";
import Iter "mo:base/Iter";

module {
    public func get_username(url: Text): Text {
        if (url.size() == 0) {
            return ""
        };

        let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(url, #char '/'));
        let lastElem : Text = urlSplitByPath[urlSplitByPath.size() - 1];
        let filterByQueryString : [Text] = Iter.toArray(Text.tokens(lastElem, #char '?'));
        let filterBySeparator : [Text] = Iter.toArray(Text.tokens(filterByQueryString[0], #char '&'));

        return filterBySeparator[0];
    };
}