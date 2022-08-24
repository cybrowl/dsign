import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Assets "Assets";
import Logger "canister:logger";
import Username "canister:username";

import Types "./types";

actor AssetsMain = {
    let ACTOR_NAME : Text = "AssetsMain";
    let CYCLE_AMOUNT : Nat = 100_000_0000_000;

    var assets_canisters : HashMap.HashMap<Text, Text> = HashMap.HashMap(0, Text.equal, Text.hash);
    stable var asset_canister_id : Text = "";

    public query func version() : async Text {
        return "0.0.1";
    };

    public shared({caller}) func create_asset_from_chunks(main_args : Types.CreateAssetMainArgs) : async Result.Result<Types.AssetMin, Text> {
        let assetsActor = actor (asset_canister_id) : Types.AssetsActor;

        let args : Types.CreateAssetArgs = {
            chunk_ids = main_args.chunk_ids;
            content_type = main_args.content_type;
            principal = caller;
        };

        let asset = await assetsActor.create_asset_from_chunks(args);

        return asset;
    };

    // ------------------------- Canister Management -------------------------
    public shared (message) func whoami() : async Principal {
        return message.caller;
    };

    private func id() : async Principal {
        return await whoami();
    };

    private func create_asset_canister() : async () {
        let tags = [ACTOR_NAME, "create_asset_canister"];

        // create canister
        let assets_main_canister_id = await id();
        await Logger.log_event(tags, debug_show(("assets_main_canister_id: ", assets_main_canister_id)));

        Cycles.add(CYCLE_AMOUNT);
        let asset_actor = await Assets.Assets(assets_main_canister_id);

        let principal = Principal.fromActor(asset_actor);
        let asset_canister_id_ = Principal.toText(principal);

        assets_canisters.put(asset_canister_id_, asset_canister_id_);

        asset_canister_id := asset_canister_id_;

        await Logger.log_event(tags, debug_show(("asset_canister_id: ", asset_canister_id)));
    };

    public shared (msg) func initialize_canisters() : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];

        // create canister
        if (asset_canister_id.size() < 1) {
            await create_asset_canister();
        } else {
            await Logger.log_event(tags, debug_show(("asset_canister_id exists: ", asset_canister_id)));
        };
    };

};