import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
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

import Utils "./utils";
import Types "./types";

actor class Assets(controller: Principal) = this {    
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
        var file_name : Text = "";
        let data_chunks_size : Nat = 0;
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
                    file_name := chunk.file_name;
                };
                case(#err err){
                   //TODO: log error
                };
            };
        };

        if (all_chunks_match_owner == false) {
            return #err("All Chunks Must Match Owner");
        };

        let self = Principal.fromActor(this);
        let canister_id : Text = Principal.toText(self);

        let asset : Types.Asset  = {
            id = asset_id;
            canister_id = canister_id;
            content_type = args.content_type;
            created = created;
            data_chunks = asset_data;
            file_name = file_name;
            owner = owner;
            data_chunks_size = asset_data.size();
        };

        assets.put(asset_id, asset);

        let asset_min : Types.AssetMin = {
            id = asset_id;
            canister_id = canister_id;
            content_type = asset.content_type;
            created = asset.created;
            file_name = file_name;
            owner = asset.owner;
            data_chunks_size = asset.data_chunks_size;
        };

        #ok(asset_min);
    };

    // ------------------------- Get Asset -------------------------
    public shared query({caller}) func http_request(request : Types.HttpRequest) : async Types.HttpResponse {
        let NOT_FOUND : [Nat8] = Blob.toArray(Text.encodeUtf8("Permission denied. Could not perform this operation"));

        if (request.method != "GET") {
            return {
                body = NOT_FOUND;
                headers = [];
                status_code = 403;
                streaming_strategy = null;
            };
        };

        let asset_id = Utils.get_asset_id(request.url);

        switch (assets.get(asset_id)) {
            case (? asset) {
                let file_name = Text.concat("attachment; filename=", asset.file_name);

                return {
                    body = Blob.toArray(asset.data_chunks[0]);
                    headers = [ ("Content-Type", asset.content_type),
                                ("accept-ranges", "bytes"),
                                ("Content-Disposition", file_name),
                                ("cache-control", "private, max-age=0") ];
                    status_code = 200;
                    streaming_strategy = create_strategy({
                        asset_id = asset_id;
                        chunk_index = 0;
                        data_chunks_size = asset.data_chunks_size;
                    });
                };
            };
            case _ {
                return {
                    body = NOT_FOUND;
                    headers = [];
                    status_code = 404;
                    streaming_strategy = null;
                };
            };
        };
    };

    private func create_strategy(args : Types.CreateStrategyArgs) : ?Types.StreamingStrategy {
        switch (create_token(args)) {
            case (null) { null };
            case (? token) {
                let self = Principal.fromActor(this);
                let canister_id : Text = Principal.toText(self);
                let canister = actor (canister_id) : actor { http_request_streaming_callback : shared () -> async () };

                return ?#Callback({
                    token;
                    callback = canister.http_request_streaming_callback;
                });
            };
        };
    };

    private func create_token(args : Types.CreateStrategyArgs) : ?Types.StreamingCallbackToken {
        if (args.chunk_index + 1 >= args.data_chunks_size) {
            null;
        } else {
            ?{
                asset_id = args.asset_id;
                chunk_index = args.chunk_index + 1;
                content_encoding = "gzip";
            };
        };
    };

    public shared query({caller}) func http_request_streaming_callback(
        st : Types.StreamingCallbackToken,
    ) : async Types.StreamingCallbackHttpResponse {

        switch (assets.get(st.asset_id)) {
            case (null) throw Error.reject("key not found: " # st.asset_id);
            case (? asset) {
                return {
                    token = create_token({
                        asset_id = st.asset_id;
                        chunk_index = st.chunk_index;
                        data_chunks_size = asset.data_chunks_size;
                    });
                    body = asset.data_chunks[st.chunk_index];
                };
            };
        };
    };
};