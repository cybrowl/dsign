import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
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
    type ImageUrl =  Types.ImageUrl;
    type ImagesUrls = Types.ImagesUrls;

    let ACTOR_NAME : Text = "SnapImages";
    let MAX_BYTES = 2_000_000;

    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);
    private var isProduction : Bool = false;

    var snap_images : HashMap.HashMap<ImageID, Image> = HashMap.HashMap(0, Text.equal, Text.hash);
    stable var snap_images_stable_storage : [(ImageID, Image)] = [];

    public query func version() : async Text {
        return "0.0.1";
    };

    public query func get_canister_id() : async Text {
        return Principal.toText(Principal.fromActor(this));
    };

    // note: this will only send one image until messages can transmit data > 2MB
    public shared (msg) func save_images(images: Images) : async ImagesUrls {
        let image_ids = Buffer.Buffer<ImageID>(0);
        let snap_images_canister_id = await get_canister_id();

        for (image in images.vals()) {
            let image_id : ImageID = ULID.toText(se.new());

            snap_images.put(image_id, image);

            image_ids.add(image_id);
        };

        let image_urls = Utils.generate_snap_image_urls(snap_images_canister_id, image_ids.toArray(), isProduction);

        return image_urls;
    };

    // serves the image to the client when requested via image url
    public shared query func http_request(req : HttpRequest) : async HttpResponse {
        let NOT_FOUND : Blob = Blob.fromArray([0]);

        //TODO: return the correct image type
        let image_id : Text = Utils.get_image_id(req.url);

        switch (snap_images.get(image_id)) {
            case (?image) {
                return {
                    status_code = 200;
                    headers = [ ("content-type", "image/png") ];
                    body = image.data;
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

    // ------------------------- System Methods -------------------------
    system func preupgrade() {
        snap_images_stable_storage := Iter.toArray(snap_images.entries());
    };

    system func postupgrade() {
        snap_images := HashMap.fromIter<ImageID, Image>(snap_images_stable_storage.vals(), 0, Text.equal, Text.hash);
        snap_images_stable_storage := [];
    };
};