import Cycles "mo:base/ExperimentalCycles";
import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Debug "mo:base/Debug";

import Snap "Snap";
import Logger "canister:logger";
import Types "./types";

actor ProjectsMain {
    type CanisterSnapID = Types.CanisterSnapID;
    type CanisterSnap = Types.CanisterSnap;
    type UserPrincipal = Types.UserPrincipal;
    type Username = Types.Username;
    type SnapID = Types.SnapID;

    let ACTOR_NAME : Text = "ProjectsMain";
    let cycleAmount : Nat = 1_000_000_000;

    // User Data Management
    var userSnapCanistersRef : H.HashMap<UserPrincipal, H.HashMap<CanisterSnapID, [SnapID]>> = H.HashMap(1, Text.equal, Text.hash);

    // Canister Data Management
    var currentEmptySnapCanisterID : Text = "";

    // User Logic Management
    public query func version() : async Text {
        return "0.0.3";
    };

    public shared (msg) func create_snap(title: Text, isPublic: Bool, ) : async () {
        let userPrincipal : UserPrincipal = Principal.toText(msg.caller);

        switch (userSnapCanistersRef.get(userPrincipal)) {
            case (?snapCanisterIds) {
                switch (snapCanisterIds.get(currentEmptySnapCanisterID)) {
                    case (?listSnapIds) {
                        //TODO: add to listSnapIds
                        // listSnapIds.put("New Snap": SnapID);
                        Debug.print(debug_show(listSnapIds));
                    };
                    case(_) {
                        //TODO: create new 
                        Debug.print(debug_show("null"));
                    };
                };
            };
            case(_) {
                var initialSnapCreation : H.HashMap<CanisterSnapID, [SnapID]> = H.HashMap(1, Text.equal, Text.hash);        
                initialSnapCreation.put(currentEmptySnapCanisterID: CanisterSnapID, ["Initial Snap"] : [SnapID]);
                userSnapCanistersRef.put(userPrincipal, initialSnapCreation);
            };
        }; 
    };

    public shared query(msg) func get_snap() : async () {
        let userPrincipal : UserPrincipal = Principal.toText(msg.caller);

        switch (userSnapCanistersRef.get(userPrincipal)) {
            case (?canisterSnaps) {
                for ((key, val) in canisterSnaps.entries()) {
                    Debug.print(debug_show(key));
                    Debug.print(debug_show(val));
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
        let canisterSnapID = Principal.toText(principal);

        // update current empty canister ID
        currentEmptySnapCanisterID := canisterSnapID;

        await Logger.log_event(tags, debug_show(("create_snap_canister", canisterSnapID)));
    };

    public shared (msg) func heart_beat() : async ()  {
        let tags = [ACTOR_NAME, "heartbeat"];

        // initialize first avatar canister
        if (currentEmptySnapCanisterID.size() < 1) {
            await Logger.log_event(tags, debug_show(("Initialize: currentEmptySnapCanisterID", currentEmptySnapCanisterID)));

            await create_snap_canister();
        };

         await Logger.log_event(tags, debug_show(("End: currentEmptySnapCanisterID", currentEmptySnapCanisterID)));
    };
};
