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

    var snap_images : H.HashMap<ImageID, Image> = H.HashMap(1, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public query func get_canister_id() : async Text {
        return Principal.toText(Principal.fromActor(this));
    };

    public shared (msg) func save_images(images: Images) : async [ImageID] {
        let image_ids = B.Buffer<ImageID>(0);

        for (image in images.vals()) {
            let image_id : ImageID = ULID.toText(se.new());

            snap_images.put(image_id, image);

            image_ids.add(image_id);
        };

        //TODO: return images_urls
        return image_ids.toArray();
    };

    // serves the image to the client when requested via image url
    public shared query func http_request(req : HttpRequest) : async HttpResponse {
        let NOT_FOUND : [Nat8] = [0];

        //TODO: return the correct image type
        let image_id : Text = Utils.get_image_id(req.url);

        switch (snap_images.get(image_id)) {
            case (?image) {
                return {
                    status_code = 200;
                    headers = [ ("content-type", "image/png") ];
                    body = image;
                };
            };
            case (_) {
                return {
                    status_code = 404;
                    headers = [ ("content-type", "image/png") ];
                    body = NOT_FOUND;
                };
            };
        };
    };
};