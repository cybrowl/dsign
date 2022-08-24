import Array "mo:base/Array";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Rand "mo:base/Random";
import Result "mo:base/Result";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import FileAssetChunks "canister:assets_file_chunks";

import Types "./types";

actor class Assets(controller: Principal) = {    
    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);

    private let assets: HashMap.HashMap<Text, Types.Asset> = HashMap.HashMap<Text, Types.Asset>(0, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    // ------------------------- Create Asset -------------------------
    public shared({caller}) func create_asset_from_chunks(args : Types.CreateAssetArgs) : async Result.Result<Types.AssetMin, Text> {
        var asset_data : [Blob] = [];
        var all_chunks_match_owner : Bool = true;

        var created : Int = 0;
        var owner : Principal = args.principal;
        var data_chunks_size : Nat = 0;
        let asset_id : Text = ULID.toText(se.new());

        if (controller != caller) {
            return #err("Not Authorized");
        };

        // get all chunks and check if owners match
        for (chunk_id in args.chunk_ids.vals()) {
            switch (await FileAssetChunks.get_chunk(chunk_id, args.principal)) {
                case(#ok chunk){
                    asset_data := Array.append<Blob>(asset_data, [chunk.data]);

                    if (owner != chunk.owner) {
                        all_chunks_match_owner := false;
                    };

                    created := chunk.created;
                    owner := chunk.owner;
                };
                case(#err err){
                   //TODO: log error
                };
            };
        };

        if (all_chunks_match_owner == false) {
            return #err("All Chunks Must Match Owner");
        };

        let asset : Types.Asset  = {
            content_type = args.content_type;
            created = created;
            data_chunks = asset_data;
            owner = owner;
            data_chunks_size = asset_data.size();
        };

        assets.put(asset_id, asset);

        let asset_min : Types.AssetMin = {
            content_type = asset.content_type;
            created = asset.created;
            owner = asset.owner;
            data_chunks_size = asset.data_chunks_size;
        };

        #ok(asset_min);
    };
};