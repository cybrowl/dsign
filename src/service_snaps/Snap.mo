import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import Username "canister:username";

import Types "./types";

actor class Snap() = this {
    type AddImgUrlSnapErr = Types.AddImgUrlSnapErr;
    type CreateSnapArgs = Types.CreateSnapArgs;
    type AssetRef = Types.AssetRef;
    type ImageRef =  Types.ImageRef;
    type Snap = Types.Snap;
    type SnapID = Types.SnapID;
    type UserPrincipal = Types.UserPrincipal;

    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);

    var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);
    stable var snaps_stable_storage : [(SnapID, Snap)] = [];

    //TODO: only allow snap_main to accesss write methods

    public shared ({caller}) func save_snap(
        args: CreateSnapArgs,
        images_ref: [ImageRef], 
        file_asset: AssetRef,
        principal: UserPrincipal) : async Result.Result<Snap, Text> {

        let snap_id =  ULID.toText(se.new());
        let snap_canister_id =  Principal.toText(Principal.fromActor(this));

        var username = "";
        switch(await Username.get_username_actor(principal)) {
            case(#ok username_) {
                username:= username_;
            };
            case(#err error) {
                return #err("Username Not Found");
            };
        };

        let snap : Snap = {
            id = snap_id;
            canister_id = snap_canister_id;
            cover_image_location = args.cover_image_location;
            created = Time.now();
            username = username;
            images_ref = images_ref;
            file_asset = file_asset;
            likes = 0;
            projects = null;
            title = args.title;
            views = 0;
        };

        snaps.put(snap_id, snap);

        return #ok(snap);
    };

    public shared ({caller}) func delete_snaps(snapIds: [SnapID]) : async () {
        for (snap_id in snapIds.vals()){
            switch (snaps.get(snap_id)){
                case null {};
                case (?snap) {
                   snaps.delete(snap_id);
                };
            }
        };
    };

    public query func get_all_snaps(snapIds: [SnapID]) : async [Snap] {
        var snaps_list = Buffer.Buffer<Snap>(0);

        for (snap_id in snapIds.vals()){
            switch (snaps.get(snap_id)){
                case null {};
                case (?snap) {
                   snaps_list.add(snap); 
                };
            }
        };

        return snaps_list.toArray();
    };

    // ------------------------- System Methods -------------------------
    system func preupgrade() {
        snaps_stable_storage := Iter.toArray(snaps.entries());
    };

    system func postupgrade() {
        snaps := HashMap.fromIter<SnapID, Snap>(snaps_stable_storage.vals(), 0, Text.equal, Text.hash);
        snaps_stable_storage := [];
    };
};