import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {
    public type Chunk = {
        data : Blob;
        file_name : Text;
    };

    public type AssetChunk = Chunk and {
        created : Int;
        owner : Principal;
    };

    public type Asset = {
        id : Text;
        canister_id : Text;
        content_type : Text;
        created : Int;
        data_chunks : [Blob];
        owner : Principal;
        data_chunks_size : Nat;
    };

    public type AssetMin = {
        id : Text;
        canister_id : Text;
        content_type : Text;
        created : Int;
        owner : Principal;
        data_chunks_size : Nat;
    };

    public type CreateAssetMainArgs = {
        chunk_ids : [Nat];
        content_type : Text;
    };

    public type CreateAssetArgs = {
        chunk_ids : [Nat];
        content_type : Text;
        principal : Principal;
    };

    public type HeaderField = (Text, Text);

    public type HttpRequest = {
        url : Text;
        method : Text;
        body : Blob;
        headers : [HeaderField];
    };

    public type HttpResponse = {
        body : [Blob];
        headers : [HeaderField];
        status_code : Nat16;
        streaming_strategy : ?StreamingStrategy;
    };

    public type CreateStrategyArgs = {
        asset_id : Text;
        chunk_index : Nat;
        data_chunks_size : Nat;
    };

    public type StreamingStrategy = {
        #Callback : {
            token : StreamingCallbackToken;
            callback : shared () -> async ();
        };
    };

    public type StreamingCallbackToken = {
        asset_id : Text;
        chunk_index : Nat;
        content_encoding : Text;
    };

    public type StreamingCallbackHttpResponse = {
        body : Blob;
        token: ?StreamingCallbackToken;
    };

    public type AssetsActor = actor {
        create_asset_from_chunks : shared (CreateAssetArgs) -> async Result.Result<AssetMin, Text>;
    };
}