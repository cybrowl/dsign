import Cycles "mo:base/ExperimentalCycles";
import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";

import Snap "Snap";
import Logger "canister:logger";
import Types "./types";

actor ProjectManager {
    type CanisterID = Types.CanisterID;
    type CanisterSnap = Types.CanisterSnap;
    type UserID = Types.UserID;
    type Username = Types.Username;
    type SnapID = Types.SnapID;

    let ACTOR_NAME : Text = "ProjectManager";
    let cycleAmount : Nat = 1_000_000_000_000;

    // User Data Management
    var canisterSnapIds : H.HashMap<UserID, [CanisterSnap]> = H.HashMap(1, Text.equal, Text.hash);

    // Canister Data Management
    var currentEmptySnapCanisterID : Text = "";

    // User Logic Management
    public query func version() : async Text {
        return "0.0.2";
    };

    public shared (msg) func create_snap() : async () {
        let userId : Text = Principal.toText(msg.caller);
        var canisterSnap : CanisterSnap =  {
            CanisterID = currentEmptySnapCanisterID;
            SnapID = "12345";
        };
    
        canisterSnapIds.put(userId, [canisterSnap]);
    };

    public shared query(msg) func get_snap() : async () {
        let userId : Text = Principal.toText(msg.caller);
        var canisterIds = canisterSnapIds.get(userId);

        Debug.print(debug_show(canisterIds))
    };

    // Canister Logic Management
    private func create_snap_canister() : async () {
        let tags = [ACTOR_NAME, "create_snap_canister"];

        // create canister
        Cycles.add(cycleAmount);
        let snapActor = await Snap.Snap();
        let principal = Principal.fromActor(snapActor);
        let canisterID = Principal.toText(principal);

        // update current empty canister ID
        currentEmptySnapCanisterID := canisterID;

        await Logger.log_event(tags, debug_show(("create_snap_canister", canisterID)));
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
