import FileAssetChunks "canister:assets_file_chunks";

actor class Assets() = {
    public query func version() : async Text {
        return "0.0.1";
    };

    public shared({caller}) func create_asset_from_chunks(chunk_ids: [Nat]) : async () {
        // todo: call asset canister to create asset
    };

};