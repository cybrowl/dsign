import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Debug "mo:base/Debug";

import Types "./types";

actor FileAssetChunks = {
    private var chunk_id_count: Nat = 0;
    private let chunks: HashMap.HashMap<Nat, Types.AssetChunk> = HashMap.HashMap<Nat, Types.AssetChunk>(0, Nat.equal, Hash.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public shared ({caller}) func create_chunk(chunk: Types.Chunk) : async Nat {
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

    //TODO: Add a delete_chunks function
};