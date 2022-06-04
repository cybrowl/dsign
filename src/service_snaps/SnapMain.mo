import B "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import H "mo:base/HashMap";
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
    type ImageID =  Types.ImageID;
    type Snap = Types.Snap;
    type SnapActor = Types.SnapActor;
    type SnapCanisterID = Types.SnapCanisterID;
    type SnapID = Types.SnapID;
    type SnapImagesActor = Types.SnapImagesActor;
    type SnapsError = Types.SnapsError;
    type Username = Types.Username;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "SnapMain";
    let CYCLE_AMOUNT : Nat = 1_000_000_000;

    // Snap Data
    var user_canisters_ref : H.HashMap<UserPrincipal, H.HashMap<SnapCanisterID, B.Buffer<SnapID>>> = H.HashMap(0, Text.equal, Text.hash);

    // holds data until filled
    // once filled, a new canister is created and assigned
    var snap_canister_id : Text = "";
    var snap_images_canister_id : Text = "";

    // ------------------------- Snaps Management -------------------------
    public shared ({caller}) func inistialize_user() : async Bool {
        let tags = [ACTOR_NAME, "inistialize_user"];
        let principal : UserPrincipal = Principal.toText(caller);

        switch (user_canisters_ref.get(principal)) {
            case (?snap_canister_ids) {
                return false;
            };
            case (_) {
                var empty_snap_canister_id_storage : H.HashMap<SnapCanisterID, B.Buffer<SnapID>> = H.HashMap(0, Text.equal, Text.hash);

                //TODO: add current snap_canister_id to SnapCanisterID
                user_canisters_ref.put(principal, empty_snap_canister_id_storage);

                return true;
            };
        };
    };

    public shared ({caller}) func create_snap(args: CreateSnapArgs) : async () {
        let tags = [ACTOR_NAME, "create_snap"];
        let principal : UserPrincipal = Principal.toText(caller);
        let has_images = args.images.size() > 0;

        // check if user exists
        switch (user_canisters_ref.get(principal)) {
            case (?snap_canister_ids) {
                // check if user has current empty snap_canister_id
                switch (snap_canister_ids.get(snap_canister_id)) {
                    // canister is not full
                    case (?snap_ids) {
                        if (has_images) {
                            let snap_images_actor = actor (snap_images_canister_id) : SnapImagesActor;
                            let snap_actor = actor (snap_canister_id) : SnapActor;

                            // save images and snap
                            let image_ids = await snap_images_actor.save_images(args.images);
                            let snap_id = await snap_actor.save_snap(args, image_ids, principal);

                            snap_ids.add(snap_id);
                        };

                        await Logger.log_event(tags, debug_show("created snap"));
                    };
                    case(_) {
                        // canister is full / snap_canister_id NOT Found
                        await Logger.log_event(tags, debug_show("canister_full"));
                        let snap_ids = B.Buffer<SnapID>(0);

                        if (has_images) {
                            let snap_images_actor = actor (snap_images_canister_id) : SnapImagesActor;
                            let snap_actor = actor (snap_canister_id) : SnapActor;

                            // save images and snap
                            let image_ids = await snap_images_actor.save_images(args.images);
                            let snap_id = await snap_actor.save_snap(args, image_ids, principal);

                            snap_ids.add(snap_id);
                        };

                        snap_canister_ids.put(snap_canister_id, snap_ids);
                        await Logger.log_event(tags, debug_show("created snap"));
                    };
                };
            };
            case(_) {
               await Logger.log_event(tags, debug_show("will return error to frontend, whereby it will call inistialize_user"));
            };
        }; 
    };

    public shared ({caller}) func get_all_snaps() : async Result.Result<[Snap], SnapsError> {
        let tags = [ACTOR_NAME, "get_all_snaps"];
        let principal : UserPrincipal = Principal.toText(caller);

        switch (user_canisters_ref.get(principal)) {
            case (?snap_canister_ids) {
                let all_snaps = B.Buffer<Snap>(0);

                for ((canister_id, snap_ids) in snap_canister_ids.entries()) {
                    let snap_actor = actor (canister_id) : SnapActor;
                    let snaps = await snap_actor.get_all_snaps(snap_ids.toArray());

                    for (snap in snaps.vals()) {
                        all_snaps.add(snap);
                    };
                };

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
        Cycles.add(CYCLE_AMOUNT);
        let snap_actor = await Snap.Snap();
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
