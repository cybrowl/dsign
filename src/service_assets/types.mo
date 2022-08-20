import Principal "mo:base/Principal";

module {
    public type Chunk = {
        data  : Blob;
        file_name : Text;
    };

    public type AssetChunk = Chunk and {
        created: Int;
        owner: Principal;
    };

    public type Asset = {
        content_type: Text;
        created: Int;
        data_chunks : [Blob];
        owner: Principal;
        total_length   : Nat;
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
        status_code : Nat8;
        streaming_strategy : ?StreamingStrategy;
    };

    public type StreamingStrategy = {
        #Callback : {
            token : StreamingCallbackToken;
            callback : shared () -> async ();
        };
    };

    public type StreamingCallbackToken = {
        key : Text;
        index : Nat;
        content_encoding : Text;
    };

    public type StreamingCallbackHttpResponse = {
        body : Blob;
        token: ?StreamingCallbackToken;
    };
}