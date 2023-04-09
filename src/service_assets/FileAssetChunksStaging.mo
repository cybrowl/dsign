import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Map "mo:hashmap/Map";
import Nat "mo:base/Nat";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Logger "canister:logger";
import HealthMetrics "canister:health_metrics";

import HealthMetricsTypes "../types/health_metrics.types";
import Types "./types";

import UtilsShared "../utils/utils";

actor FileAssetChunksStaging = {
	type Payload = HealthMetricsTypes.Payload;

	let { nhash } = Map;

	private stable var chunk_id_count : Nat = 0;

	private var chunks = Map.new<Nat, Types.AssetChunk>(nhash);
	stable var chunks_stable_storage : [(Nat, Types.AssetChunk)] = [];

	let VERSION : Nat = 7;
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

		ignore Map.put(chunks, nhash, chunk_id_count, asset_chunk);

		return chunk_id_count;
	};

	public shared ({ caller }) func delete_chunks(chunk_ids : [Nat], owner : Principal) : async () {
		for (chunk_id in chunk_ids.vals()) {
			switch (Map.get(chunks, nhash, chunk_id)) {
				case (?chunk) {
					if (chunk.owner == owner) {
						Map.delete(chunks, nhash, chunk_id);
					};
				};
				case (_) {};
			};
		};
	};

	public query func get_chunk(chunk_id : Nat, principal : Principal) : async Result.Result<Types.AssetChunk, Text> {
		switch (Map.get(chunks, nhash, chunk_id)) {
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

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("chunks_size", Int.toText(Map.size(chunks))),
			("chunk_id_count", Int.toText(chunk_id_count)),
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
				("assets_num", Map.size(chunks)),
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

	// ------------------------- SYSTEM METHODS -------------------------
	system func preupgrade() {
		chunks_stable_storage := Iter.toArray(Map.entries(chunks));
	};

	system func postupgrade() {
		chunks := Map.fromIter<Nat, Types.AssetChunk>(chunks_stable_storage.vals(), nhash);

		chunks_stable_storage := [];
	};
};
