import { Buffer } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";

import HealthMetricsTypes "../types/health_metrics.types";
import Types "./types";

import UtilsShared "../utils/utils";

actor Explore = {
	type SnapCanisterId = Types.SnapCanisterId;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;

	type Payload = HealthMetricsTypes.Payload;

	var snaps : HashMap.HashMap<SnapID, SnapPublic> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var snaps_stable_storage : [(SnapID, SnapPublic)] = [];

	var snaps_authorized_can_ids : HashMap.HashMap<SnapCanisterId, SnapCanisterId> = HashMap.HashMap(0, Text.equal, Text.hash);

	let ACTOR_NAME : Text = "Explore";

	public query func ping() : async Text {
		return "pong";
	};

	public shared func save_snap(snap : SnapPublic) : async Text {
		snaps.put(snap.id, snap);

		return "Saved Snap";
	};

	//TODO: given a list of snaps (id and canister id) it should call that canister to get latest snap

	public shared func delete_snaps(snap_ids : [SnapID]) : async () {
		for (snap_id in snap_ids.vals()) {
			switch (snaps.get(snap_id)) {
				case null {};
				case (?snap) {
					snaps.delete(snap_id);
				};
			};
		};
	};

	public query func get_all_snaps() : async [SnapPublic] {
		return Iter.toArray(snaps.vals());
	};

	public query func length() : async Nat {
		return snaps.size();
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public shared func health() : async Payload {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("snaps_size", Int.toText(snaps.size())),
			("cycles_balance", Int.toText(UtilsShared.get_cycles_balance())),
			("memory_in_mb", Int.toText(UtilsShared.get_memory_in_mb())),
			("heap_in_mb", Int.toText(UtilsShared.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);

		let log_payload : Payload = {
			metrics = [
				("snaps_num", snaps.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(Explore));
			parent_canister_id = "";
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		snaps_stable_storage := Iter.toArray(snaps.entries());
	};

	system func postupgrade() {
		snaps := HashMap.fromIter<SnapID, SnapPublic>(
			snaps_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		snaps_stable_storage := [];
	};
};
