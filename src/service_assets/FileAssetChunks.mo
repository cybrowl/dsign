import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Types "./types";

actor FileAssetChunks = {
	private var chunk_id_count : Nat = 0;
	private let chunks : HashMap.HashMap<Nat, Types.AssetChunk> = HashMap.HashMap<Nat, Types.AssetChunk>(
		0,
		Nat.equal,
		Hash.hash
	);
	let VERSION : Nat = 3;

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

	public query func health() : async Types.Health {
		return {
			chunks_size = chunks.size();
			memory = Prim.rts_memory_size();
			heap = Prim.rts_heap_size();
		};
	};
};
