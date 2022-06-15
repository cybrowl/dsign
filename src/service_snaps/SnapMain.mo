import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Hashmap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Result "mo:base/Result";

import Logger "canister:logger";
import Snap "Snap";
import SnapImages "SnapImages";

import Types "./types";

actor SnapMain {
    type CreateSnapArgs = Types.CreateSnapArgs;
    type CreateSnapErr = Types.CreateSnapErr;
    type FinalizeSnapArgs = Types.FinalizeSnapArgs;
    type Snap = Types.Snap;
    type SnapActor = Types.SnapActor;
    type SnapCanisterID = Types.SnapCanisterID;
    type SnapID = Types.SnapID;
    type SnapImagesActor = Types.SnapImagesActor;
    type SnapsError = Types.SnapsError;
    type Username = Types.Username;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "SnapMain";
    let CYCLE_AMOUNT : Nat = 100_000_0000_000;

    // Snap Data
    var user_canisters_ref : Hashmap.HashMap<UserPrincipal, Hashmap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>>> = Hashmap.HashMap(0, Principal.equal, Principal.hash);

    // holds data until filled
    // once filled, a new canister is created and assigned
    var snap_canister_id : Text = "";
    var snap_images_canister_id : Text = "";

    // ------------------------- Snaps Management -------------------------
    //Todo: Call this in the client
    public shared ({caller}) func create_user_snap_storage() : async Bool {
        let tags = [ACTOR_NAME, "create_user_snap_storage"];

        switch (user_canisters_ref.get(caller)) {
            case (?snap_canister_ids) {
                return false;
            };
            case (_) {
                var empty_snap_canister_id_storage : Hashmap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>> = Hashmap.HashMap(0, Text.equal, Text.hash);

                user_canisters_ref.put(caller, empty_snap_canister_id_storage);

                return true;
            };
        };
    };

    public shared ({caller}) func create_snap(args: CreateSnapArgs) : async Result.Result<Snap, CreateSnapErr> {
        let tags = [ACTOR_NAME, "create_snap"];
        let has_images = args.images.size() > 0;

        Debug.print(debug_show("create_snap caller", caller));

        if (has_images == false) {
            return #err(#NoImageToSave);
        };

        // check if user exists
        switch (user_canisters_ref.get(caller)) {
            case (?snap_canister_ids) {
                // check if user has current empty snap_canister_id
                switch (snap_canister_ids.get(snap_canister_id)) {
                    // canister is not full
                    case (?snap_ids) {
                        await Logger.log_event(tags, debug_show("current snap_canister_id"));
                        let snap_images_actor = actor (snap_images_canister_id) : SnapImagesActor;
                        let snap_actor = actor (snap_canister_id) : SnapActor;

                        // save images and snap
                        // note: this will only send one image until messages can transmit data > 2MB
                        let image_urls = await snap_images_actor.save_images(args.images);
                        let snap = await snap_actor.save_snap(args, image_urls, caller);

                        switch(snap) {
                            case(#err err) {
                                return #err(#UsernameNotFound);
                            };
                            case(#ok snap) {
                                snap_ids.add(snap.id);
                                #ok(snap);
                            };
                        };
                    };
                    case(_) {
                        // canister is full / snap_canister_id NOT Found
                        await Logger.log_event(tags, debug_show("canister_full/snap_canister_id_empty"));
                        let snap_ids = Buffer.Buffer<SnapID>(0);

                        let snap_images_actor = actor (snap_images_canister_id) : SnapImagesActor;
                        let snap_actor = actor (snap_canister_id) : SnapActor;

                        // save images and snap
                        // note: this will only send one image until messages can transmit data > 2MB
                        let image_urls = await snap_images_actor.save_images(args.images);
                        // let snap_id = await snap_actor.save_snap(args, image_urls, caller);
                        switch(await snap_actor.save_snap(args, image_urls, caller))  {
                            case(#err error) {
                                return #err(#UsernameNotFound);
                            };
                            case(#ok snap) {
                                snap_ids.add(snap.id);
                                snap_canister_ids.put(snap_canister_id, snap_ids);

                                return #ok(snap);
                            };
                        };
                    };
                };
            };
            case(_) {
               return #err(#UserNotFound);
            };
        }; 
    };

    //note: this will be deprecated in future when message transmission > 8MB
    public shared ({caller}) func finalize_snap_creation(args: FinalizeSnapArgs) : async () {
        let tags = [ACTOR_NAME, "finalize_snap_creation"];
        // save image to snap_images_canister_id -> image_url
        // find snap_canister_id that has matching snap_id -> snap_canister_id
        // add image_url to snap_id
    };

    public shared ({caller}) func get_all_snaps() : async Result.Result<[Snap], SnapsError> {
        let tags = [ACTOR_NAME, "get_all_snaps"];

        await Logger.log_event(tags, debug_show(("caller", caller)));

        switch (user_canisters_ref.get(caller)) {
            case (?snap_canister_ids) {
                let all_snaps = Buffer.Buffer<Snap>(0);
                let can_ids = Iter.toArray(snap_canister_ids.entries());

                await Logger.log_event(tags, debug_show("can_ids"));

                for ((canister_id, snap_ids) in snap_canister_ids.entries()) {
                    let snap_actor = actor (canister_id) : SnapActor;
                    let snaps = await snap_actor.get_all_snaps(snap_ids.toArray());

                    Debug.print(debug_show("snaps"));

                    for (snap in snaps.vals()) {
                        all_snaps.add(snap);
                    };
                };

                await Logger.log_event(tags, debug_show("ok"));
                return #ok(all_snaps.toArray());
            };
            case (_) {
                #err(#UserNotFound)
            };
        };
    };

    // ------------------------- Canister Management -------------------------
    public query func version() : async Text {
        return "0.0.1";
    };

    private func create_snap_canister() : async () {
        let tags = [ACTOR_NAME, "create_snap_canister"];

        // create canister
        await Logger.log_event(tags, debug_show(("cycles: before")));
        Cycles.add(CYCLE_AMOUNT);
        let snap_actor = await Snap.Snap();
        await Logger.log_event(tags, debug_show(("cycles: after actor"), Cycles.balance()));
        let principal = Principal.fromActor(snap_actor);
        let snap_canister_id_ = Principal.toText(principal);

        snap_canister_id := snap_canister_id_;

        await Logger.log_event(tags, debug_show(("snap_canister_id: ", snap_canister_id)));
    };

    private func create_snap_images_canister() : async () {
        let tags = [ACTOR_NAME, "create_snap_images_canister"];

        // create canister
        Cycles.add(CYCLE_AMOUNT);
        let snap_images_actor = await SnapImages.SnapImages();
        let principal = Principal.fromActor(snap_images_actor);
        let snap_images_canister_id_ = Principal.toText(principal);

        snap_images_canister_id := snap_images_canister_id_;

        await Logger.log_event(tags, debug_show(("snap_images_canister_id: ", snap_images_canister_id)));
    };

    public shared (msg) func initialize_canisters(snapCanisterId: ?Text, snapImagesCanisterId: ?Text) : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];

        // create snap
        if (snap_canister_id.size() < 1) {
            switch (snapCanisterId) {
                case null  {
                    await create_snap_canister();
                };
                case (?canister_id) {
                    await Logger.log_event(tags, debug_show(("snap initialized", canister_id)));
                    snap_canister_id := canister_id;
                };
            };
        } else {
            await Logger.log_event(tags, debug_show(("snap exists", snap_canister_id)));
        };

        // create snap images
        if (snap_images_canister_id.size() < 1) {
            switch (snapImagesCanisterId) {
                case null  {
                    await create_snap_images_canister();
                };
                case (?canister_id) {
                    await Logger.log_event(tags, debug_show(("snap_images initialized", canister_id)));
                    snap_images_canister_id := canister_id;
                };
            };
        } else {
            await Logger.log_event(tags, debug_show(("snap_images exists", snap_images_canister_id)));
        };
    };
};
