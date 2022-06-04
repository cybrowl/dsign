import Array "mo:base/Array";
import B "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Types "./types";

module {
    type ImageID =  Types.ImageID;
    type ImageUrl = Types.ImageUrl;
    type ImagesUrls = Types.ImagesUrls;

    public func get_image_id(url: Text) : Text {
        if (url.size() == 0) {
            return ""
        };

        let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(url, #char '/'));
        let lastElem : Text = urlSplitByPath[urlSplitByPath.size() - 1];
        let filterByQueryString : [Text] = Iter.toArray(Text.tokens(lastElem, #char '?'));
        let filterBySeparator : [Text] = Iter.toArray(Text.tokens(filterByQueryString[0], #char '&'));

        return filterBySeparator[0];
    };

    public func generate_snap_image_url(snapImagesCanisterID: Text, imageID: ImageID) : ImageUrl {
        let url = Text.join("", (["https://", snapImagesCanisterID, ".raw.ic0.app", "/snap_image/", imageID].vals()));

        return url;
    };

    public func generate_snap_image_urls(snapImagesCanisterID: Text, imageIds: [ImageID]) : ImagesUrls {
        var image_urls = B.Buffer<ImageUrl>(0);

        for (image_id in imageIds.vals()) {
            var image_url = generate_snap_image_url(snapImagesCanisterID, image_id);

            image_urls.add(image_url);
        };

        return image_urls.toArray();
    };

    public func is_valid_image(img: [Nat8]) : Bool {
        var compare = B.Buffer<Nat8>(0);

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