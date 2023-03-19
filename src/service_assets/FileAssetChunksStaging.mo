import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CanisterIdsLedger "canister:canister_ids_ledger";
import HealthMetrics "canister:health_metrics";

import CanisterIdsLedgerTypes "../types/canidster_ids_ledger.types";
import HealthMetricsTypes "../types/health_metrics.types";
import Types "./types";

import UtilsShared "../utils/utils";

actor FileAssetChunksStaging = {
	type Payload = HealthMetricsTypes.Payload;

	private var chunk_id_count : Nat = 0;
	private let chunks : HashMap.HashMap<Nat, Types.AssetChunk> = HashMap.HashMap<Nat, Types.AssetChunk>(
		0,
		Nat.equal,
		Hash.hash
	);

	let VERSION : Nat = 5;
	let ACTOR_NAME : Text = "FileAssetChunksStaging";

	public shared ({ caller }) func create_chunk(chunk : Types.Chunk) : async Nat {
		//TODO: check username to stop spam
		//TODO: add limit to number of file space per user

		chunk_id_count := chunk_id_count + 1;

		let asset_chunk : Types.AssetChunk = {
			created = Time.now();
			data = chunk.data;
			file_name = chunk.file_name;
			owner = caller;
		};

		chunks.put(chunk_id_count, asset_chunk);

		return chunk_id_count;
	};

	public shared ({ caller }) func delete_chunks(chunk_ids : [Nat], owner : Principal) : async () {
		for (chunk_id in chunk_ids.vals()) {
			switch (chunks.get(chunk_id)) {
				case (?chunk) {
					if (chunk.owner == owner) {
						chunks.delete(chunk_id);
					};
				};
				case (_) {};
			};
		};
	};

	public query func get_chunk(chunk_id : Nat, principal : Principal) : async Result.Result<Types.AssetChunk, Text> {
		switch (chunks.get(chunk_id)) {
			case (?chunk) {
				if (chunk.owner != principal) {
					return #err("Chunk Not Owned By Caller");
				} else {
					return #ok(chunk);
				};
			};
			case (_) {
				return #err("Chunk Not Found");
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let log_payload : Payload = {
			metrics = [
				("assets_num", chunks.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(FileAssetChunksStaging));
			parent_canister_id = "";
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	public shared (message) func whoami() : async Principal {
		return message.caller;
	};

	public shared func init() : async Text {
		let principal_canister = await whoami();
		let canister_id = Principal.toText(principal_canister);
		let is_prod = Text.equal(
			Principal.toText(principal_canister),
			"jfpyd-maaaa-aaaag-aatxq-cai"
		);

		switch (await CanisterIdsLedger.canister_exists(principal_canister)) {
			case (true) {
				return "Canister Already Exists";
			};
			case (false) {
				let canister_child : CanisterIdsLedgerTypes.CanisterInfo = {
					created = Time.now();
					id = canister_id;
					name = "root";
					parent_name = ACTOR_NAME;
					isProd = is_prod;
				};

				ignore CanisterIdsLedger.save_canister(canister_child);

				return "Canister Created";
			};
		};
	};
};
