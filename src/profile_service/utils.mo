import Array "mo:base/Array";
import B "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

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

    public func is_valid_image(img: [Nat8]): Bool {
        var compare = B.Buffer<Nat8>(1);

        let gif : [Nat8] = [71,  73,  70,  56];
        let jpeg : [Nat8] = [255, 216, 255, 224];
        let jpeg2 : [Nat8] = [255, 216, 255, 225];
        let png : [Nat8] = [137,  80,  78,  71];

        for (i in Iter.range(0, 3)) {
            compare.add(img[i]);
        };

        let compareArr = compare.toArray();

        let isGIF = Array.equal(gif, compareArr, isEq);
        let isJPEG = Array.equal(jpeg, compareArr, isEq);
        let isJPEG2 = Array.equal(jpeg2, compareArr, isEq);
        let isPNG = Array.equal(png, compareArr, isEq);

        if (isGIF) {
            return true;
        } else if (isJPEG) {
            return true;
        } else if (isJPEG2) {
            return true;
        } else if (isPNG) {
            return true;
        } else {
            return false;
        }
    };

    func isEq(a: Nat8, b: Nat8): Bool { a == b };
}