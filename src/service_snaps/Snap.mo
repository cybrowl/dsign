import H "mo:base/HashMap";
import B "mo:base/Buffer";
import Principal "mo:base/Principal";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import Types "./types";

actor class Snap() = this {
    type CreateSnapArgs = Types.CreateSnapArgs;
    type ImagesUrls =  Types.ImagesUrls;
    type Snap = Types.Snap;
    type SnapID = Types.SnapID;
    type UserPrincipal = Types.UserPrincipal;

    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);

    var snaps : H.HashMap<SnapID, Snap> = H.HashMap(0, Text.equal, Text.hash);

    //TODO: only allow main to accesss methods

    public query func version() : async Text {
        return "0.0.1";
    };

    public query func get_canister_id() : async Text {
        return Principal.toText(Principal.fromActor(this));
    };

    public shared ({caller}) func save_snap(
        args: CreateSnapArgs,
        imageUrls: ImagesUrls, 
        principal: UserPrincipal) : async SnapID {

        let snap_id =  ULID.toText(se.new());

        let snap : Snap = {
            id = snap_id;
            cover_image_location = args.cover_image_location;
            created = Time.now();
            creator = Principal.toText(principal);
            image_urls = imageUrls;
            is_public = args.is_public;
            likes = 0;
            projects = null;
            title = args.title;
            views = 0;
        };

        snaps.put(snap_id, snap);

        return snap_id;
    };

    public query func get_all_snaps(snapIds: [SnapID]) : async [Snap] {
        var snaps_list = B.Buffer<Snap>(0);

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
};