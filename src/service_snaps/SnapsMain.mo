import B "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import H "mo:base/HashMap";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import Logger "canister:logger";
import Snap "Snap";
import SnapImages "SnapImages";
import Types "./types";

actor SnapsMain {
    type CreateSnapArgs = Types.CreateSnapArgs;
    type ImageID =  Types.ImageID;
    type SnapCanisterID = Types.SnapCanisterID;
    type SnapID = Types.SnapID;
    type SnapImagesActor = Types.SnapImagesActor;
    type Username = Types.Username;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "SnapsMain";
    let cycleAmount : Nat = 1_000_000_000;

    // User Data Management
    var userSnapCanistersRef : H.HashMap<UserPrincipal, H.HashMap<SnapCanisterID, B.Buffer<SnapID>>> = H.HashMap(1, Text.equal, Text.hash);

    // holds snap data until filled
    // once filled, a new canister is created and assigned
    var snapStorageCanister : Text = "";
    var snapImagesStorageCanister : Text = "";

    public query func version() : async Text {
        return "0.0.1";
    };

    // User Management
    public shared ({caller}) func create_snap(args: CreateSnapArgs) : async () {
        let tags = [ACTOR_NAME, "create_snap"];
        let userPrincipal : UserPrincipal = Principal.toText(caller);
        var imageIds = [];

        // check if user exists
        switch (userSnapCanistersRef.get(userPrincipal)) {
            case (?snapCanisterIds) {

                // check if user has current storage canister
                switch (snapCanisterIds.get(snapStorageCanister)) {
                    case (?listOfSnapIds) {
                        // current storage canister can be used to add snap

                        // store images
                        let snapImages = actor (snapImagesStorageCanister) : SnapImagesActor;
                        switch (await snapImages.add(args.images)) {
                            case (imageIds) {
                                await Logger.log_event(tags, debug_show(("imageIds: ", imageIds)));

                                imageIds:= imageIds;
                            };
                            case _ {};
                        };

                        // TODO: create snap
                        // TODO: add snap to userSnapCanistersRef
                        // TODO: add snap id to listOfSnapIds

                        listOfSnapIds.add("second");

                        await Logger.log_event(tags, debug_show(("listOfSnapIds: ", listOfSnapIds.toArray())));
                    };
                    case(_) {
                        // user doesn't have current empty snap storage canister

                        // store images
                        // create snap
                        // add snap to snapStorageCanister
                        // add snapCanisterID to snapCanisterIds with listOfSnapIds
                        await Logger.log_event(tags, debug_show("adding snapStorageCanister to snapCanisterIds"));
                    };
                };
            };
            case(_) {
                // create initial SnapCanisterID for user
                await Logger.log_event(tags, debug_show(("user has zero snapStorageCanisterIds", userPrincipal)));

                // store images
                let snapImages = actor (snapImagesStorageCanister) : SnapImagesActor;
                switch (await snapImages.add(args.images)) {
                    case (imageIds) {
                        await Logger.log_event(tags, debug_show(("imageIds: ", imageIds)));

                        imageIds:= imageIds;
                    };
                    case _ {};
                };

                var initialSnapCreation : H.HashMap<SnapCanisterID, B.Buffer<SnapID>> = H.HashMap(0, Text.equal, Text.hash);
                var listOfSnapIds = B.Buffer<SnapID>(0);
                listOfSnapIds.add("");
    
                initialSnapCreation.put(snapStorageCanister: SnapCanisterID, listOfSnapIds);

                userSnapCanistersRef.put(userPrincipal, initialSnapCreation);
            };
        }; 
    };

    public shared query({caller}) func get_all_snaps() : async [Snap] {
        let userPrincipal : UserPrincipal = Principal.toText(caller);

        switch (userSnapCanistersRef.get(userPrincipal)) {
            case (?snapCanisterIds) {
                for ((key, val) in snapCanisterIds.entries()) {
                    Debug.print(debug_show(key));
                };
            };
            case(_) {
                Debug.print(debug_show("null"));
            };
        };
    };

    // Canister Management
    private func create_snap_canister() : async () {
        let tags = [ACTOR_NAME, "create_snap_canister"];

        // create canister
        Cycles.add(cycleAmount);
        let snapActor = await Snap.Snap();
        let principal = Principal.fromActor(snapActor);
        let snapCanisterID = Principal.toText(principal);

        snapStorageCanister := snapCanisterID;

        await Logger.log_event(tags, debug_show(("snapStorageCanister: ", snapStorageCanister)));
    };

    private func create_snap_images_canister() : async () {
        let tags = [ACTOR_NAME, "create_snap_images_canister"];

        // create canister
        Cycles.add(cycleAmount);
        let snapImagesActor = await SnapImages.SnapImages();
        let principal = Principal.fromActor(snapImagesActor);
        let snapImagesCanisterID = Principal.toText(principal);

        snapImagesStorageCanister := snapImagesCanisterID;

        await Logger.log_event(tags, debug_show(("snapImagesCanisterID: ", snapImagesCanisterID)));
    };

    public shared (msg) func initialize_canisters(snapCanisterID: ?Text, snapImagesCanisterID: ?Text) : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];

        // create snap
        if (snapStorageCanister.size() < 1) {
            switch (snapCanisterID) {
                case null  {
                    await create_snap_canister();
                };
                case (?canisterID) {
                    await Logger.log_event(tags, debug_show(("assign snap local: ", canisterID)));
                    snapStorageCanister := canisterID;
                };
            };
        } else {
            await Logger.log_event(tags, debug_show(("snap exists: ", snapStorageCanister)));
        };

        // create snap images
        if (snapImagesStorageCanister.size() < 1) {
            switch (snapImagesCanisterID) {
                case null  {
                    await create_snap_images_canister();
                };
                case (?canisterID) {
                    await Logger.log_event(tags, debug_show(("assign snap_images local: ", canisterID)));
                    snapImagesStorageCanister := canisterID;
                };
            };
        } else {
            await Logger.log_event(tags, debug_show(("snap_images exists: ", snapImagesStorageCanister)));
        };
    };
};
