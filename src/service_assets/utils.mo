import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";

module {
    public func get_asset_id(url: Text) : Text {
        let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(url, #char '/'));
        let lastElem : Text = urlSplitByPath[urlSplitByPath.size() - 1];
        let filterByQueryString : [Text] = Iter.toArray(Text.tokens(lastElem, #char '?'));
        
        return filterByQueryString[0];
    };
}