import B "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import H "mo:base/HashMap";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import Logger "canister:logger";
import Snap "Snap";
import Types "./types";

actor SnapsMain {
    type SnapID = Types.SnapID;
    type SnapStorageCanisterID = Types.SnapStorageCanisterID;
    type Username = Types.Username;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "SnapsMain";
    let cycleAmount : Nat = 1_000_000_000;

    // User Data Management
    var userSnapCanistersRef : H.HashMap<UserPrincipal, H.HashMap<SnapStorageCanisterID, B.Buffer<SnapID>>> = H.HashMap(1, Text.equal, Text.hash);
    var snapStorageCanister : Text = "";

    // User Logic Management
    public query func version() : async Text {
        return "0.0.1";
    };

    public shared (msg) func create_snap(title: Text, isPublic: Bool, ) : async () {
        let tags = [ACTOR_NAME, "create_snap"];
        let userPrincipal : UserPrincipal = Principal.toText(msg.caller);

        // check if user has a snapStorageCanister
        switch (userSnapCanistersRef.get(userPrincipal)) {
            case (?snapStorageCanisterIds) {
                // check if user has current Not Filled snapStorageCanister
                switch (snapStorageCanisterIds.get(snapStorageCanister)) {
                    case (?listOfSnapIds) {
                        // create snap
                        // add snap to snapStorageCanister
                        // add snap id to listOfSnapIds

                        listOfSnapIds.add("second");

                        await Logger.log_event(tags, debug_show(("listOfSnapIds: ", listOfSnapIds.toArray())));
                    };
                    case(_) {
                        // user doesn't have current empty snap storage canister
                        // create snap
                        // add snap to snapStorageCanister
                        // add snapStorageCanisterID to snapStorageCanisterIds with listOfSnapIds
                        await Logger.log_event(tags, debug_show("adding snapStorageCanister to snapStorageCanisterIds"));
                    };
                };
            };
            case(_) {
                // create initial SnapStorageCanisterID for user
                await Logger.log_event(tags, debug_show(("user has zero snapStorageCanisterIds", userPrincipal)));

                var initialSnapCreation : H.HashMap<SnapStorageCanisterID, B.Buffer<SnapID>> = H.HashMap(1, Text.equal, Text.hash);
                var listOfSnapIds = B.Buffer<SnapID>(1);
                listOfSnapIds.add("");
    
                initialSnapCreation.put(snapStorageCanister: SnapStorageCanisterID, listOfSnapIds);

                userSnapCanistersRef.put(userPrincipal, initialSnapCreation);
            };
        }; 
    };

    public shared query(msg) func get_snap() : async () {
        let userPrincipal : UserPrincipal = Principal.toText(msg.caller);

        switch (userSnapCanistersRef.get(userPrincipal)) {
            case (?snapStorageCanisterIds) {
                for ((key, val) in snapStorageCanisterIds.entries()) {
                    Debug.print(debug_show(key));
                };
            };
            case(_) {
                Debug.print(debug_show("null"));
            };
        };
    };

    // Canister Logic Management
    private func create_snap_canister() : async () {
        let tags = [ACTOR_NAME, "create_snap_canister"];

        // create canister
        Cycles.add(cycleAmount);
        let snapActor = await Snap.Snap();
        let principal = Principal.fromActor(snapActor);
        let snapStorageCanisterID = Principal.toText(principal);

        // update current empty canister ID
        snapStorageCanister := snapStorageCanisterID;

        await Logger.log_event(tags, debug_show(("snapStorageCanister: ", snapStorageCanister)));
    };

    public shared (msg) func heart_beat() : async ()  {
        let tags = [ACTOR_NAME, "heartbeat"];

        if (snapStorageCanister.size() < 1) {
            await Logger.log_event(tags, debug_show(("Initialize: snapStorageCanister", snapStorageCanister)));

            await create_snap_canister();
        };

         await Logger.log_event(tags, debug_show(("End: snapStorageCanister", snapStorageCanister)));
    };
};
