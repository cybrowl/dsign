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
    type Snap = Types.Snap;
    type SnapActor = Types.SnapActor;
    type SnapCanisterID = Types.SnapCanisterID;
    type SnapID = Types.SnapID;
    type SnapImagesActor = Types.SnapImagesActor;
    type Username = Types.Username;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "SnapsMain";
    let cycleAmount : Nat = 1_000_000_000;

    // User Data Management
    var userCanistersRef : H.HashMap<UserPrincipal, H.HashMap<SnapCanisterID, B.Buffer<SnapID>>> = H.HashMap(1, Text.equal, Text.hash);

    // holds data until filled
    // once filled, a new canister is created and assigned
    var snapCanisterId : Text = "";
    var snapImagesCanisterId : Text = "";

    public query func version() : async Text {
        return "0.0.1";
    };

    // User Management
    private func create_user_first_canister(args: CreateSnapArgs, userPrincipal: UserPrincipal) : async ()  {
        let tags = [ACTOR_NAME, "create_user_first_canister"];

        var initialCanisterRef : H.HashMap<SnapCanisterID, B.Buffer<SnapID>> = H.HashMap(0, Text.equal, Text.hash);
        var snapIds = B.Buffer<SnapID>(0);

        let snapImages = actor (snapImagesCanisterId) : SnapImagesActor;
        let snapActor = actor (snapCanisterId) : SnapActor;

        if (args.images.size() > 0) {
            // store images
            let imageIds = await snapImages.add(args.images);

            // create snap
            let snapId = await snapActor.create(args, imageIds, userPrincipal);

            snapIds.add(snapId);
        };

        initialCanisterRef.put(snapCanisterId: SnapCanisterID, snapIds);

        userCanistersRef.put(userPrincipal, initialCanisterRef);
        await Logger.log_event(tags, debug_show(("created")));
    };

    public shared ({caller}) func create_snap(args: CreateSnapArgs) : async () {
        let tags = [ACTOR_NAME, "create_snap"];
        let userPrincipal : UserPrincipal = Principal.toText(caller);

        // check if user exists
        switch (userCanistersRef.get(userPrincipal)) {
            case (?canisterIds) {
                // check if user has current snapCanisterId
                switch (canisterIds.get(snapCanisterId)) {
                    case (?snapIds) {
                        let snapImages = actor (snapImagesCanisterId) : SnapImagesActor;
                        let snapActor = actor (snapCanisterId) : SnapActor;

                        if (args.images.size() > 0) {
                            // store images
                            let imageIds = await snapImages.add(args.images);

                            // create snap
                            let snapId = await snapActor.create(args, imageIds, userPrincipal);

                            snapIds.add(snapId);
                        };

                        await Logger.log_event(tags, debug_show("created snap"));
                    };
                    case(_) {
                        // user data is part of filled snap canister

                        await Logger.log_event(tags, debug_show("user snapCanisterId is outdated"));
                    };
                };
            };
            case(_) {
               await create_user_first_canister(args, userPrincipal);
            };
        }; 
    };

    // public shared query({caller}) func get_all_snaps() : async [Snap] {
    //     let userPrincipal : UserPrincipal = Principal.toText(caller);

    //     switch (userCanistersRef.get(userPrincipal)) {
    //         case (?canisterIds) {
    //             for ((key, val) in canisterIds.entries()) {
    //                 Debug.print(debug_show(key));
    //             };
    //         };
    //         case(_) {
    //             Debug.print(debug_show("null"));
    //         };
    //     };
    // };

    // Canister Management
    private func create_snap_canister() : async () {
        let tags = [ACTOR_NAME, "create_snap_canister"];

        // create canister
        Cycles.add(cycleAmount);
        let snapActor = await Snap.Snap();
        let principal = Principal.fromActor(snapActor);
        let snapCanisterID = Principal.toText(principal);

        snapCanisterId := snapCanisterID;

        await Logger.log_event(tags, debug_show(("snapCanisterId: ", snapCanisterId)));
    };

    private func create_snap_images_canister() : async () {
        let tags = [ACTOR_NAME, "create_snap_images_canister"];

        // create canister
        Cycles.add(cycleAmount);
        let snapImagesActor = await SnapImages.SnapImages();
        let principal = Principal.fromActor(snapImagesActor);
        let snapImagesCanisterID = Principal.toText(principal);

        snapImagesCanisterId := snapImagesCanisterID;

        await Logger.log_event(tags, debug_show(("snapImagesCanisterID: ", snapImagesCanisterID)));
    };

    public shared (msg) func initialize_canisters(snapCanisterID: ?Text, snapImagesCanisterID: ?Text) : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];

        // create snap
        if (snapCanisterId.size() < 1) {
            switch (snapCanisterID) {
                case null  {
                    await create_snap_canister();
                };
                case (?canisterID) {
                    await Logger.log_event(tags, debug_show(("assign snap local: ", canisterID)));
                    snapCanisterId := canisterID;
                };
            };
        } else {
            await Logger.log_event(tags, debug_show(("snap exists: ", snapCanisterId)));
        };

        // create snap images
        if (snapImagesCanisterId.size() < 1) {
            switch (snapImagesCanisterID) {
                case null  {
                    await create_snap_images_canister();
                };
                case (?canisterID) {
                    await Logger.log_event(tags, debug_show(("assign snap_images local: ", canisterID)));
                    snapImagesCanisterId := canisterID;
                };
            };
        } else {
            await Logger.log_event(tags, debug_show(("snap_images exists: ", snapImagesCanisterId)));
        };
    };
};
