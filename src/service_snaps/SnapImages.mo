import B "mo:base/Buffer";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Rand "mo:base/Random";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import Types "./types";
import Utils "./utils";

actor class SnapImages() = this {
    type HttpRequest = Types.HttpRequest;
    type HttpResponse =  Types.HttpResponse;
    type Image = Types.Image;
    type ImageID = Types.ImageID;
    type Images = Types.Images;

    let ACTOR_NAME : Text = "SnapImages";
    let MAX_BYTES = 2_000_000;
    
    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);

    var snapImages : H.HashMap<ImageID, Image> = H.HashMap(1, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public query func get_canister_id() : async Text {
        return Principal.toText(Principal.fromActor(this));
    };

    public shared (msg) func add(images: Images) : async [ImageID] {
        var snapInfo = B.Buffer<ImageID>(0);

        for (image in images.vals()) {
            let imageID : ImageID = ULID.toText(se.new());

            snapImages.put(imageID, image);
            snapInfo.add(imageID);
        };

        return snapInfo.toArray();
    };

    public shared query func http_request(req : HttpRequest) : async HttpResponse {
        let NOT_FOUND : [Nat8] = [0];

        Debug.print(debug_show("req", req));

        let imageID : Text = Utils.get_image_id(req.url);

        Debug.print(debug_show("imageID", imageID));

        switch (snapImages.get(imageID)) {
            case (?image) {
                return {
                    status_code = 200;
                    headers = [ ("content-type", "image/png") ];
                    body = image;
                };
            };
            case (null) {
                return {
                    status_code = 404;
                    headers = [ ("content-type", "image/png") ];
                    body = NOT_FOUND;
                };
            };
        };
    };
};