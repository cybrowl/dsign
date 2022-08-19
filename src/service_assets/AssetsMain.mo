import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import Assets "Assets";
import Logger "canister:logger";
import Username "canister:username";

actor AssetsMain = {
    let ACTOR_NAME : Text = "AssetsMain";
    let CYCLE_AMOUNT : Nat = 100_000_0000_000;

    var assets : HashMap.HashMap<Text, Text> = HashMap.HashMap(0, Text.equal, Text.hash);
    stable var asset_canister_id : Text = "";

    public query func version() : async Text {
        return "0.0.1";
    };

    public shared({caller}) func create_asset_from_chunks() : async () {
        // todo: call asset canister to create asset
    };

    // ------------------------- Canister Management -------------------------
    private func create_asset_canister() : async () {
        let tags = [ACTOR_NAME, "create_asset_canister"];

        // create canister
        Cycles.add(CYCLE_AMOUNT);
        let asset_actor = await Assets.Assets();

        let principal = Principal.fromActor(asset_actor);
        let asset_canister_id_ = Principal.toText(principal);

        asset_canister_id := asset_canister_id_;

        await Logger.log_event(tags, debug_show(("asset_canister_id: ", asset_canister_id)));
    };

    public shared (msg) func initialize_canisters() : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];

        // create canister
        if (asset_canister_id.size() < 1) {
            await create_asset_canister();
        } else {
            await Logger.log_event(tags, debug_show(("assets exists", asset_canister_id)));
        };
    };

};