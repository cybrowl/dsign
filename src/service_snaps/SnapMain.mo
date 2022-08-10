import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
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
    type DeleteAllSnapsErr = Types.DeleteAllSnapsErr;
    type FinalizeSnapArgs = Types.FinalizeSnapArgs;
    type GetAllSnapsErr = Types.GetAllSnapsErr;
    type Snap = Types.Snap;
    type SnapActor = Types.SnapActor;
    type SnapCanisterID = Types.SnapCanisterID;
    type SnapID = Types.SnapID;
    type SnapImagesActor = Types.SnapImagesActor;
    type Username = Types.Username;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "SnapMain";
    let CYCLE_AMOUNT : Nat = 100_000_0000_000;

    // Snap Data
    var user_canisters_ref : HashMap.HashMap<UserPrincipal, HashMap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>>> = HashMap.HashMap(0, Principal.equal, Principal.hash);
    stable var user_canisters_ref_storage : [var (UserPrincipal, [(SnapCanisterID, [SnapID])])] = [var];

    // holds data until filled
    // once filled, a new canister is created and assigned
    stable var snap_canister_id : Text = "";
    stable var snap_images_canister_id : Text = "";

    // ------------------------- Snaps Management -------------------------
    // TODO: Call this in the client
    public shared ({caller}) func create_user_snap_storage() : async Bool {
        let tags = [ACTOR_NAME, "create_user_snap_storage"];

        switch (user_canisters_ref.get(caller)) {
            case (?snap_canister_ids) {
                return false;
            };
            case (_) {
                var empty_snap_canister_id_storage : HashMap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>> = HashMap.HashMap(0, Text.equal, Text.hash);

                user_canisters_ref.put(caller, empty_snap_canister_id_storage);

                return true;
            };
        };
    };

    public shared ({caller}) func create_snap(args: CreateSnapArgs) : async Result.Result<Snap, CreateSnapErr> {
        let tags = [ACTOR_NAME, "create_snap"];
        let has_image = args.images.size() > 0;
        let too_many_images = args.images.size() > 1;

        if (has_image == false) {
            return #err(#NoImageToSave);
        };

        if (too_many_images == true) {
            return #err(#OneImageMax);
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
                        // note: image_urls only stores one image for now
                        let image_urls = await snap_images_actor.save_images(args.images);
                        let snap = await snap_actor.save_snap(args, image_urls, caller);

                        switch(snap) {
                            case(#err error) {
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
                        let image_urls = await snap_images_actor.save_images(args.images);
                        let snap = await snap_actor.save_snap(args, image_urls, caller);

                        switch(snap)  {
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
        let snap_images_actor = actor (snap_images_canister_id) : SnapImagesActor;
        let snap_actor = actor (args.canister_id) : SnapActor;

        let image_urls = await snap_images_actor.save_images(args.images);

        // TODO: only allow 4 images per snap
        ignore await snap_actor.add_img_url_to_snap(image_urls[0], args.snap_id, caller);
    };

    public shared ({caller}) func get_all_snaps() : async Result.Result<[Snap], GetAllSnapsErr> {
        let tags = [ACTOR_NAME, "get_all_snaps"];

        switch (user_canisters_ref.get(caller)) {
            case (?snap_canister_ids) {
                let all_snaps = Buffer.Buffer<Snap>(0);
                let can_ids = Iter.toArray(snap_canister_ids.entries());

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

    public shared ({caller}) func delete_snaps(snapIds: [SnapID]) : async Result.Result<Text, DeleteAllSnapsErr> {
        let tags = [ACTOR_NAME, "delete_snaps"];

        switch (user_canisters_ref.get(caller)) {
            case (?snap_canister_ids) {
                for ((canister_id, snap_ids) in snap_canister_ids.entries()) {
                    //todo: delete snapIds in snap_ids

                    let snap_actor = actor (canister_id) : SnapActor;
                    await snap_actor.delete_snaps(snapIds);
                };

                return #ok("");
            };
            case (_) {
                #err(#UserNotFound)
            };
        };
    };

    // ------------------------- Canister Management -------------------------
    public query func version() : async Text {
        return "0.0.2";
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

    public shared (msg) func initialize_canisters() : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];

        // create snap
        if (snap_canister_id.size() < 1) {
            await create_snap_canister();
        } else {
            await Logger.log_event(tags, debug_show(("snap exists", snap_canister_id)));
        };

        // create snap images
        if (snap_images_canister_id.size() < 1) {
            await create_snap_images_canister();
        } else {
            await Logger.log_event(tags, debug_show(("snap_images exists", snap_images_canister_id)));
        };
    };

    // ------------------------- System Methods -------------------------
    system func preupgrade() {
        var anon_principal = Principal.fromText("aaaaa-aa");
        user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));

        var i = 0;
        for ((user_principal, snap_canister_ids) in user_canisters_ref.entries()) {
            var canisters : HashMap.HashMap<SnapCanisterID, [SnapID]> = HashMap.HashMap(0, Text.equal, Text.hash);

            for ((snap_canister_id, snap_ids) in snap_canister_ids.entries()) {
                var snap_ids_array = snap_ids.toArray();
                canisters.put(snap_canister_id, snap_ids_array);
            };

            user_canisters_ref_storage[i] := (user_principal, Iter.toArray(canisters.entries()));
            i += 1;
        };
    };

    system func postupgrade() {
        var user_canisters_ref_temp : HashMap.HashMap<UserPrincipal, HashMap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>>> = HashMap.HashMap(0, Principal.equal, Principal.hash);

        for ((user_principal, snap_canister_ids) in user_canisters_ref_storage.vals()) {
            var canisters : HashMap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>> = HashMap.HashMap(0, Text.equal, Text.hash);

            for ((snap_canister_id, snap_ids) in snap_canister_ids.vals()) {
                var snap_ids_buffer : Buffer.Buffer<SnapID> = Buffer.fromArray(snap_ids);
                canisters.put(snap_canister_id, snap_ids_buffer);
            };

            user_canisters_ref_temp.put(user_principal, canisters);
        };

        user_canisters_ref := user_canisters_ref_temp;
        var anon_principal = Principal.fromText("aaaaa-aa");
        user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));
    };
};
