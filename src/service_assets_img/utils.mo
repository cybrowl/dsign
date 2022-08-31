import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

module {
    public func is_valid_image(img: Blob) : Bool {
        var img_arr = Blob.toArray(img);
        var compare = Buffer.Buffer<Nat8>(0);

        let gif : [Nat8] = [71,  73,  70,  56];
        let jpeg : [Nat8] = [255, 216, 255, 224];
        let jpeg2 : [Nat8] = [255, 216, 255, 225];
        let png : [Nat8] = [137,  80,  78,  71];

        for (i in Iter.range(0, 3)) {
            compare.add(img_arr[i]);
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