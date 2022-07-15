import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
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
    type ImagesUrls =  Types.ImagesUrls;
    type ImageUrl =  Types.ImageUrl;
    type SaveSnapErr = Types.SaveSnapErr;
    type Snap = Types.Snap;
    type SnapID = Types.SnapID;
    type UserPrincipal = Types.UserPrincipal;

    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);

    var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);

    //TODO: only allow snap_main to accesss write methods
    public query func version() : async Text {
        return "0.0.1";
    };

    public query func get_canister_id() : async Text {
        return Principal.toText(Principal.fromActor(this));
    };

    //TODO: remove
    public shared ({caller}) func save_snap(
        args: CreateSnapArgs,
        imageUrls: ImagesUrls, 
        principal: UserPrincipal) : async Result.Result<Snap, SaveSnapErr> {

        let snap_id =  ULID.toText(se.new());
        let snap_canister_id =  await get_canister_id();

        var username = "";
        switch(await Username.get_username_actor(principal)) {
            case(#ok username_) {
                username:= username_;
            };
            case(#err error) {
                return #err(#UsernameNotFound);
            };
        };

        let snap : Snap = {
            id = snap_id;
            canister_id = snap_canister_id;
            cover_image_location = args.cover_image_location;
            created = Time.now();
            creator = username;
            image_urls = imageUrls;
            is_public = args.is_public;
            likes = 0;
            projects = null;
            title = args.title;
            views = 0;
        };

        snaps.put(snap_id, snap);

        return #ok(snap);
    };

    public shared ({caller}) func add_img_url_to_snap(
        img_url: ImageUrl,
        snap_id:  SnapID,
        principal: UserPrincipal) : async Result.Result<Snap, AddImgUrlSnapErr> {

        var username = "";
        switch(await Username.get_username_actor(principal)) {
            case(#ok username_) {
                username:= username_;
            };
            case(#err error) {
                return #err(#UsernameNotFound);
            };
        };

        switch(snaps.get(snap_id)) {
            case(?snap) {

                if (Text.notEqual(username, snap.creator)) {
                    return #err(#UserNotCreator); 
                };

                if (snap.image_urls.size() == 4) {
                    return #err(#ImgLimitReached); 
                };

                // TODO: refactor to not use append
                let update_img_urls = Array.append(snap.image_urls, [img_url]);
                let updated_snap: Snap = {
                    id = snap.id;
                    canister_id = snap.canister_id;
                    cover_image_location = snap.cover_image_location;
                    created = snap.created;
                    creator = snap.creator;
                    image_urls = update_img_urls;
                    is_public = snap.is_public;
                    likes = snap.likes;
                    projects = snap.projects;
                    title = snap.title;
                    views = snap.views;
                };

                snaps.put(snap_id, updated_snap);

                return #ok(updated_snap);

            };
            case(_) {
                return #err(#SnapNotFound);
            };
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
};