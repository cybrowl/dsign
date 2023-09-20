import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Map "mo:hashmap/Map";
import Nat "mo:base/Nat";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Logger "canister:logger";

import Types "./types";

import Utils "./utils";
import UtilsShared "../utils/utils";

actor ImageAssetStaging = {
	type AssetImg = Types.AssetImg;

	type AssetImgErr = {
		#AssetNotFound;
		#NotOwnerOfAsset;
	};

	let { nhash } = Map;

	private var asset_id_count : Nat = 0;
	private let assets = Map.new<Nat, Types.AssetImg>(nhash);

	let ACTOR_NAME : Text = "ImageAssetsStaging";
	let VERSION : Nat = 6;

	public shared ({ caller }) func create_asset(img : Types.Img) : async Nat {
		//TODO: check username to stop spam
		//TODO: check user storage usage

		// TODO: check if img is valid
		// let is_valid_image = Utils.is_valid_image(img.data);

		// if (is_valid_image == false) {
		//     return 0;
		// };

		asset_id_count := asset_id_count + 1;

		let asset_chunk : Types.AssetImg = {
			created = Time.now();
			data = img.data;
			file_format = img.file_format;
			owner = caller;
		};

		ignore Map.put(assets, nhash, asset_id_count, asset_chunk);

		return asset_id_count;
	};

	public shared ({ caller }) func delete_assets(asset_ids : [Nat], owner : Principal) : async () {
		for (asset_id in asset_ids.vals()) {
			switch (Map.get(assets, nhash, asset_id)) {
				case (?asset) {
					if (asset.owner == owner) {
						Map.delete(assets, nhash, asset_id);
					};
				};
				case (_) {};
			};
		};
	};

	public query func get_asset(asset_id : Nat, owner : Principal) : async Result.Result<AssetImg, AssetImgErr> {
		switch (Map.get(assets, nhash, asset_id)) {
			case (?asset) {
				if (asset.owner != owner) {
					return #err(#NotOwnerOfAsset);
				} else {
					return #ok(asset);
				};
			};
			case (_) {
				return #err(#AssetNotFound);
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async () {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("assets_size", Int.toText(Map.size(assets))),
			("asset_id_count", Int.toText(asset_id_count)),
			("cycles_balance", Int.toText(UtilsShared.get_cycles_balance())),
			("memory_in_mb", Int.toText(UtilsShared.get_memory_in_mb())),
			("heap_in_mb", Int.toText(UtilsShared.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);
	};

	public query func cycles_low() : async Bool {
		return UtilsShared.get_cycles_low();
	};
};
