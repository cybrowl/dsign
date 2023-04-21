import Array "mo:base/Array";
import Blob "mo:base/Blob";
import { Buffer; toArray } "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

module {
	public func get_image_id(url : Text) : Text {
		if (url.size() == 0) {
			return "";
		};

		let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(url, #char '/'));
		let lastElem : Text = urlSplitByPath[urlSplitByPath.size() - 1];
		let filterByQueryString : [Text] = Iter.toArray(Text.tokens(lastElem, #char '?'));
		let filterBySeparator : [Text] = Iter.toArray(Text.tokens(filterByQueryString[0], #char '&'));

		return filterBySeparator[0];
	};

	public func is_valid_image(img : Blob) : Bool {
		var img_arr = Blob.toArray(img);
		var compare = Buffer<Nat8>(0);

		let gif : [Nat8] = [71, 73, 70, 56];
		let jpeg : [Nat8] = [255, 216, 255, 224];
		let jpeg2 : [Nat8] = [255, 216, 255, 225];
		let png : [Nat8] = [137, 80, 78, 71];

		for (i in Iter.range(0, 3)) {
			compare.add(img_arr[i]);
		};

		let compareArr = toArray(compare);

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
		};
	};

	public func generate_image_url(
		canister_id : Text,
		image_id : Text,
		asset_type : Text,
		isProduction : Bool
	) : Text {
		var url = Text.join(
			"",
			(["https://", canister_id, ".raw.icp0.io", "/image/", asset_type, "/", image_id].vals())
		);

		if (isProduction == false) {
			url := Text.join(
				"",
				(["http://localhost:8080/image/", asset_type, "/", image_id, "?canisterId=", canister_id].vals())
			);
		};

		return url;
	};

	func isEq(a : Nat8, b : Nat8) : Bool { a == b };
};
