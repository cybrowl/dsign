import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Text "mo:base/Text";

import Types "./types";

module {
	type ChunkInfo = Types.ChunkInfo;

	private type GenerateAssetUrlArgs = {
		file_id : Text;
		canister_id : Text;
		is_prod : Bool;
		port : Text;
	};

	public func get_file_id(url : Text) : Text {
		let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(url, #char '/'));
		let lastElem : Text = urlSplitByPath[urlSplitByPath.size() - 1];
		let filterByQueryString : [Text] = Iter.toArray(Text.tokens(lastElem, #char '?'));

		return filterByQueryString[0];
	};

	public func generate_file_url(args : GenerateAssetUrlArgs) : Text {
		var url = Text.join(
			"",
			(["https://", args.canister_id, ".raw.icp0.io", "/file/", args.file_id].vals())
		);

		if (args.is_prod == false) {
			url := Text.join(
				"",
				(["http://", args.canister_id, ".raw.localhost:", args.port, "/file/", args.file_id].vals())
			);
		};

		return url;
	};

	public func compare(a : ChunkInfo, b : ChunkInfo) : Order.Order {
		if (a.order < b.order) {
			return #less;
		};
		if (a.order > b.order) {
			return #greater;
		};
		return #equal;
	};
};
