import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Types "./types";
import Utils "./utils";

actor ImageAssetStaging = {
	type AssetImg = Types.AssetImg;

	type AssetImgErr = {
		#AssetNotFound;
		#NotOwnerOfAsset;
	};

	private var asset_id_count : Nat = 0;
	private let assets : HashMap.HashMap<Nat, Types.AssetImg> = HashMap.HashMap<Nat, Types.AssetImg>(
		0,
		Nat.equal,
		Hash.hash
	);

	let VERSION : Nat = 3;

	public shared ({ caller }) func create_asset(img : Types.Img) : async Nat {
		//TODO: check username to stop spam
		//TODO: add limit to number of file space per user

		// TODO: check if img is valid
		// let is_valid_image = Utils.is_valid_image(img.data);

		// if (is_valid_image == false) {
		// 	return 0;
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

	public query func health() : async Types.Health {
		return {
			assets_size = assets.size();
			memory = Prim.rts_memory_size();
			heap = Prim.rts_heap_size();
		};
	};

	public query func is_full() : async Bool {
		let MAX_SIZE_THRESHOLD_MB : Float = 3500;

		let rts_memory_size : Nat = Prim.rts_memory_size();
		let mem_size : Float = Float.fromInt(rts_memory_size);
		let memory_in_megabytes = Float.abs(mem_size * 0.000001);

		if (memory_in_megabytes > MAX_SIZE_THRESHOLD_MB) {
			return true;
		} else {
			return false;
		};
	};
};
