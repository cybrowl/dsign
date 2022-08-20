import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import FileAssetChunks "canister:assets_file_chunks";

import Types "./types";

actor class Assets() = {
     private let assets: HashMap.HashMap<Text, Types.Asset> = HashMap.HashMap<Text, Types.Asset>(0, Text.equal, Text.hash);
    
    public query func version() : async Text {
        return "0.0.1";
    };

    private func get_chunks_to_create_asset(chunk_ids: [Nat], content_type: Text, principal: Principal) : async Types.Asset {
        var asset_data : [Blob] = [];
        var has_looped_once : Bool = false;

        var created : Int = 1;
        var owner : Principal = principal;
        var total_length : Nat = 0;

        for (chunk_id in chunk_ids.vals()) {
            switch (await FileAssetChunks.get_chunk(chunk_id, principal)) {
                case(#ok chunk){
                    asset_data := Array.append<Blob>(asset_data, [chunk.data]);

                    if (has_looped_once == false) {
                        has_looped_once := true;

                        created := chunk.created;
                        owner := chunk.owner;
                    };
                };
                case(#err err){
                   //TODO: log error
                };
            };
        };

        let asset : Types.Asset  = {
            content_type = content_type;
            created = created;
            data_chunks = asset_data;
            owner = owner;
            total_length = asset_data.size();
        };

        return asset;
    };

    public shared({caller}) func create_asset_from_chunks(chunk_ids: [Nat], content_type: Text, principal: Principal) : async () {
        // todo: call file asset chunks to get the chunks
        var asset : Types.Asset = await get_chunks_to_create_asset(chunk_ids, content_type, principal);
    };

};