import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Logger "canister:logger";
import HealthMetrics "canister:health_metrics";

import HealthMetricsTypes "../types/health_metrics.types";
import Types "./types";

import Utils "./utils";
import UtilsShared "../utils/utils";

actor ImageAssetStaging = {
	type AssetImg = Types.AssetImg;

	type AssetImgErr = {
		#AssetNotFound;
		#NotOwnerOfAsset;
	};

	type Payload = HealthMetricsTypes.Payload;

	private var asset_id_count : Nat = 0;
	private let assets : HashMap.HashMap<Nat, Types.AssetImg> = HashMap.HashMap<Nat, Types.AssetImg>(
		0,
		Nat.equal,
		Hash.hash
	);

	let ACTOR_NAME : Text = "ImageAssetsStaging";
	let VERSION : Nat = 5;

	public shared ({ caller }) func create_asset(img : Types.Img) : async Nat {
		//TODO: check username to stop spam
		//TODO: add limit to number of file space per user

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

		assets.put(asset_id_count, asset_chunk);

		return asset_id_count;
	};

	public shared ({ caller }) func delete_assets(asset_ids : [Nat], owner : Principal) : async () {
		for (asset_id in asset_ids.vals()) {
			switch (assets.get(asset_id)) {
				case (?asset) {
					if (asset.owner == owner) {
						assets.delete(asset_id);
					};
				};
				case (_) {};
			};
		};
	};

	public query func get_asset(asset_id : Nat, owner : Principal) : async Result.Result<AssetImg, AssetImgErr> {
		switch (assets.get(asset_id)) {
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

	public shared func health() : async Payload {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("assets_size", Int.toText(assets.size())),
			("asset_id_count", Int.toText(asset_id_count)),
			("cycles_balance", Int.toText(UtilsShared.get_cycles_balance())),
			("memory_in_mb", Int.toText(UtilsShared.get_memory_in_mb())),
			("heap_in_mb", Int.toText(UtilsShared.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);

		let log_payload : Payload = {
			metrics = [
				("images_num", assets.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(ImageAssetStaging));
			parent_canister_id = "";
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};
};
