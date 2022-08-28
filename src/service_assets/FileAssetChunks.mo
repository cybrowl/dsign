import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Prim "mo:⛔";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Debug "mo:base/Debug";

import Username "canister:username";

import Types "./types";

actor FileAssetChunks = {
    private var chunk_id_count : Nat = 0;
    private let chunks : HashMap.HashMap<Nat, Types.AssetChunk> = HashMap.HashMap<Nat, Types.AssetChunk>(0, Nat.equal, Hash.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public shared ({caller}) func create_chunk(chunk: Types.Chunk) : async Nat {
        //TODO: check username to stop spam
        
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

    public shared ({caller}) func delete_chunks(chunk_ids: [Nat]) : async () {
        for (chunk_id in chunk_ids.vals()) {
            chunks.delete(chunk_id);
        }
    };

    public query func get_chunk(chunk_id: Nat, principal: Principal) : async Result.Result<Types.AssetChunk, Text> {
        switch (chunks.get(chunk_id)) {
            case (?chunk) {
                if (chunk.owner != principal) {
                    return #err("Chunk Not Owned By Caller");
                } else {
                    return #ok(chunk);
                }
            };
            case (_) {
                return #err("Chunk Not Found");
            };
        };
    };

    public query func get_chunks_size() : async Nat {
        return chunks.size();
    };

    public query func get_memory_size() : async Nat {
        let rts_memory_size : Nat = Prim.rts_memory_size();
        
        return rts_memory_size;
    };

    public query func get_heap_size() : async Nat {        
        return Prim.rts_heap_size();
    };
};