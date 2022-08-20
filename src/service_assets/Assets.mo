import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import FileAssetChunks "canister:assets_file_chunks";

import Types "./types";

actor class Assets() = {
     private let assets: HashMap.HashMap<Text, Types.Asset> = HashMap.HashMap<Text, Types.Asset>(0, Text.equal, Text.hash);
    
    public query func version() : async Text {
        return "0.0.1";
    };

    private func get_chunks_to_create_asset(chunk_ids: [Nat], principal: Principal) : async [Blob] {
         var asset_data : [Blob] = [];

         for (chunk_id in chunk_ids.vals()) {
            switch (await FileAssetChunks.get_chunk(chunk_id, principal)) {
                case(#ok chunk){
                    asset_data := Array.append<Blob>(asset_data, [chunk.data]);
                };
                case(#err err){
                   //TODO: log error
                };
            };
         };

         return asset_data;
    };

    public shared({caller}) func create_asset_from_chunks(chunk_ids: [Nat], principal: Principal) : async () {
        // todo: call file asset chunks to get the chunks
        var asset : [Blob] = await get_chunks_to_create_asset(chunk_ids, principal);
    };

};