import { Buffer; toArray } "mo:base/Buffer";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Prim "mo:⛔";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";

module {
	type ChunkInfo = Types.ChunkInfo;

	private type GenerateAssetUrlArgs = {
		file_id : Text;
		canister_id : Text;
		is_prod : Bool;
		port : Text;
	};

	let { hashNat } = Map;

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
				(["http://", "127.0.0.1:", args.port, "/file/", args.file_id, "?canisterId=", args.canister_id].vals())
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
