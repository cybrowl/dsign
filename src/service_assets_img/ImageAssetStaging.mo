import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Types "./types";
import Utils "./utils";

actor ImageAssetStaging = {
    type AssetImg = Types.AssetImg;

    type AssetImgErr = {
        #NotOwnerOfAsset;
        #AssetNotFound;
    };

    private var asset_id_count : Nat = 0;
    private let assets : HashMap.HashMap<Nat, Types.AssetImg> = HashMap.HashMap<Nat, Types.AssetImg>(0, Nat.equal, Hash.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public shared ({caller}) func create_asset(img: Types.Img) : async Nat {
        //TODO: check username to stop spam
        
        let is_valid_image = Utils.is_valid_image(img.data);

        if (is_valid_image == false) {
            return 0;
        };

        asset_id_count := asset_id_count + 1;

        let asset_chunk : Types.AssetImg = {
            created = Time.now();
            data = img.data;
            file_format = img.file_format;
            owner = caller;
        };

        assets.put(asset_id_count, asset_chunk);

        return asset_id_count;
    };

    public shared ({caller}) func delete_assets(asset_ids: [Nat]) : async () {
        for (asset_id in asset_ids.vals()) {
            assets.delete(asset_id);
        }
    };

    public query func get_asset(asset_id: Nat, owner: Principal) : async Result.Result<AssetImg, AssetImgErr> {
        switch (assets.get(asset_id)) {
            case (?asset) {
                if (asset.owner != owner) {
                    return #err(#NotOwnerOfAsset);
                } else {
                    return #ok(asset);
                }
            };
            case (_) {
                return #err(#AssetNotFound);
            };
        };
    };
};