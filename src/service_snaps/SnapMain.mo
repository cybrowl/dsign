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

import Assets "../service_assets/Assets";
import ImageAssets "../service_assets_img/ImageAssets";
import Logger "canister:logger";
import Snap "Snap";

import Types "./types";
import AssetTypes "../service_assets/types";

actor SnapMain {
    type AssetsActor = Types.AssetsActor;
    type CreateAssetArgs = Types.CreateAssetArgs;
    type CreateSnapArgs = Types.CreateSnapArgs;
    type CreateSnapErr = Types.CreateSnapErr;
    type DeleteAllSnapsErr = Types.DeleteAllSnapsErr;
    type GetAllSnapsErr = Types.GetAllSnapsErr;
    type ImageAssetsActor = Types.ImageAssetsActor;
    type ImageRef = Types.ImageRef;
    type Snap = Types.Snap;
    type SnapActor = Types.SnapActor;
    type SnapCanisterID = Types.SnapCanisterID;
    type SnapID = Types.SnapID;
    type Username = Types.Username;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "SnapMain";
    let CYCLE_AMOUNT : Nat = 100_000_0000_000;

    // Snap Data
    var user_canisters_ref : HashMap.HashMap<UserPrincipal, HashMap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>>> = HashMap.HashMap(0, Principal.equal, Principal.hash);
    stable var user_canisters_ref_storage : [var (UserPrincipal, [(SnapCanisterID, [SnapID])])] = [var];

    // holds data until filled
    // once filled, a new canister is created and assigned
    stable var assets_canister_id : Text = "";
    stable var image_assets_canister_id : Text = "";
    stable var snap_canister_id : Text = "";

    // ------------------------- Snaps Management -------------------------
    public shared ({caller}) func create_user_snap_storage() : async Bool {
        let tags = [ACTOR_NAME, "create_user_snap_storage"];

        switch (user_canisters_ref.get(caller)) {
            case (?snap_canister_ids) {
                ignore Logger.log_event(tags, "exists, user_snap_storage");

                return false;
            };
            case (_) {
                var empty_snap_canister_id_storage : HashMap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>> = HashMap.HashMap(0, Text.equal, Text.hash);

                user_canisters_ref.put(caller, empty_snap_canister_id_storage);

                ignore Logger.log_event(tags, "created, user_snap_storage");

                return true;
            };
        };
    };

    public shared ({caller}) func create_snap(args: CreateSnapArgs) : async Result.Result<Snap, CreateSnapErr> {
        let tags = [ACTOR_NAME, "create_snap"];
        let is_anonymous = Principal.isAnonymous(caller);
        let has_image = args.img_asset_ids.size() > 0;
        let too_many_images = args.img_asset_ids.size() > 4;

        if (is_anonymous == true) {
            return #err(#UserAnonymous);
        };

        if (has_image == false) {
            return #err(#NoImageToSave);
        };

        if (too_many_images == true) {
            return #err(#FourImagesMax);
        };

        // get user snap canister ids
        var snap_canister_ids : HashMap.HashMap<SnapCanisterID, Buffer.Buffer<SnapID>> = HashMap.HashMap(0, Text.equal, Text.hash);
        switch (user_canisters_ref.get(caller)) {
            case (?snap_canister_ids_) {
                snap_canister_ids := snap_canister_ids_;
            };
            case(_) {
               return #err(#UserNotFound);
            };
        };

        // get snap ids from current canister id
        var snap_ids = Buffer.Buffer<SnapID>(0);
        var snap_ids_found = false;
        switch (snap_canister_ids.get(snap_canister_id)) {
            case (?snap_ids_) {
                ignore Logger.log_event(tags, debug_show("snap_ids found for current empty canister"));

                snap_ids := snap_ids_;
                snap_ids_found := true;
            };
            case(_) {
                ignore Logger.log_event(tags, debug_show("snap_ids NOT found"));
            };
        };

        let image_assets_actor = actor (image_assets_canister_id) : ImageAssetsActor;
        let snap_actor = actor (snap_canister_id) : SnapActor;
        let assets_actor = actor (assets_canister_id) : AssetsActor;

        // save images from img_asset_ids
        let image_ref : ImageRef = {canister_id = ""; id = ""; url = ""};
        var images_ref = [image_ref];
        switch(await image_assets_actor.save_images(args.img_asset_ids, "snap", caller)) {
            case(#err err) {
                return #err(#ErrorCall(debug_show(err)));
            };
            case(#ok images_ref_) {
                images_ref:= images_ref_;
            };
        };

        // create asset from chunks
        var file_asset = {canister_id = ""; id = ""; url = ""; is_public = false};
        switch (args.file_asset) {
            case null {};
            case (?fileAsset){
                let file_asset_args : CreateAssetArgs = {
                    chunk_ids = fileAsset.chunk_ids;
                    content_type = fileAsset.content_type;
                    is_public = fileAsset.is_public;
                    principal = caller;
                };

                switch(await assets_actor.create_asset_from_chunks(file_asset_args)) {
                    case(#err err) {
                        return #err(#ErrorCall(debug_show(err)));
                    };
                    case(#ok file_asset_) {
                        file_asset:= file_asset_;
                    };
                };
            };
        };

        // save snap
        switch(await snap_actor.create_snap(args, images_ref, file_asset, caller)) {
            case(#err err) {
                return #err(#ErrorCall(debug_show(err)));
            };
            case(#ok snap) {
                snap_ids.add(snap.id);
                if (snap_ids_found == false) {
                    snap_canister_ids.put(snap_canister_id, snap_ids);
                };

                //TODO: remove owner from snap
                #ok(snap);
            };
        };
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
    private func create_assets_canister(snap_main_principal : Principal) : async () {
        Cycles.add(CYCLE_AMOUNT);
        let assets_actor = await Assets.Assets(snap_main_principal);
        let principal = Principal.fromActor(assets_actor);

        assets_canister_id := Principal.toText(principal);
    };

    private func create_image_assets_canister(snap_main_principal : Principal) : async () {
        Cycles.add(CYCLE_AMOUNT);
        let image_assets_actor = await ImageAssets.ImageAssets(snap_main_principal);
        let principal = Principal.fromActor(image_assets_actor);

        image_assets_canister_id := Principal.toText(principal);
    };

    private func create_snap_canister(snap_main_principal : Principal) : async () {
        Cycles.add(CYCLE_AMOUNT);
        let snap_actor = await Snap.Snap(snap_main_principal);
        let principal = Principal.fromActor(snap_actor);

        snap_canister_id := Principal.toText(principal);
    };

    public shared (msg) func initialize_canisters() : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];
        let snap_main_principal = Principal.fromActor(SnapMain);

        // create assets canister
        if (assets_canister_id.size() < 1) {
            await create_assets_canister(snap_main_principal);

            ignore Logger.log_event(tags, debug_show(("created, assets_canister_id: ", assets_canister_id)));
        } else {
            ignore Logger.log_event(tags, debug_show(("exists, assets_canister_id: ", assets_canister_id)));
        };

        // create image assets canister
        if (image_assets_canister_id.size() < 1) {
            await create_image_assets_canister(snap_main_principal);

            ignore Logger.log_event(tags, debug_show(("created, image_assets_canister_id: ", image_assets_canister_id)));
        } else {
            ignore Logger.log_event(tags, debug_show(("exists, image_assets_canister_id: ", image_assets_canister_id)));
        };

        // create snap canister
        if (snap_canister_id.size() < 1) {
            await create_snap_canister(snap_main_principal);

            ignore Logger.log_event(tags, debug_show(("created, snap_canister_id: ", snap_canister_id)));
        } else {
            ignore Logger.log_event(tags, debug_show(("exists, snap_canister_id: ", snap_canister_id)));
        };
    };

    // ------------------------- System Methods -------------------------
    system func preupgrade() {
        var anon_principal = Principal.fromText("2vxsx-fae");
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
        var anon_principal = Principal.fromText("2vxsx-fae");
        user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));
    };
};
