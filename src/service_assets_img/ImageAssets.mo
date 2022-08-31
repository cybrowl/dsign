import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Rand "mo:base/Random";
import Result "mo:base/Result";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import ImageAssetStaging "canister:assets_img_staging";

import Types "./types";
import Utils "./utils";

actor class ImageAssets(controller: Principal) = this {
    type HttpRequest = Types.HttpRequest;
    type HttpResponse =  Types.HttpResponse;
    type AssetImg = Types.AssetImg;
    type ImageID = Types.ImageID;
    type ImageRef = Types.ImageRef;
    type ImagesRef =  Types.ImagesRef;

    let ACTOR_NAME : Text = "ImageAssets";
    let VERSION : Text = "0.0.1";

    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);
    private var isProduction : Bool = false;

    var image_assets : HashMap.HashMap<ImageID, AssetImg> = HashMap.HashMap(0, Text.equal, Text.hash);
    stable var image_assets_stable_storage : [(ImageID, AssetImg)] = [];

    public query func version() : async Text {
        return VERSION;
    };

    public shared ({caller}) func save_images(img_asset_ids: [Nat], owner: Principal) : async Result.Result<[ImageRef], Text> {
        if (controller != caller) {
            return #err("Not Authorized");
        };

        let images_ref = Buffer.Buffer<ImageRef>(0);

        for (asset_id in img_asset_ids.vals()) {
            switch (await ImageAssetStaging.get_asset(asset_id, owner)) {
                case(#ok asset){

                    if (asset.owner != owner) {
                        return #err("Not Authorized");
                    };

                    let image_id : ImageID = ULID.toText(se.new());
                    image_assets.put(image_id, asset);

                    let image_ref = {
                        canister_id = Principal.toText(Principal.fromActor(this));
                        id = image_id;
                        url = "";
                    };

                    images_ref.add(image_ref);

                    return #ok(images_ref.toArray());
                };
                case(#err err){
                   //TODO: log error
                };
            };
        };
    };

    // serves the image to the client when requested via image url
    public shared query func http_request(req : HttpRequest) : async HttpResponse {
        let NOT_FOUND : Blob = Blob.fromArray([0]);

        //TODO: return the correct image type
        let image_id : Text = Utils.get_image_id(req.url);

        switch (image_assets.get(image_id)) {
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
        image_assets_stable_storage := Iter.toArray(image_assets.entries());
    };

    system func postupgrade() {
        image_assets := HashMap.fromIter<ImageID, AssetImg>(image_assets_stable_storage.vals(), 0, Text.equal, Text.hash);
        image_assets_stable_storage := [];
    };
};