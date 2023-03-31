import { Buffer; toArray } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import CanisterLedgerTypes "../types/canidster_ids_ledger.types";
import HealthMetricsTypes "../types/health_metrics.types";
import Types "./types";

import Logger "canister:logger";

import UtilsShared "../utils/utils";

actor CanisterIdsLedger = {
	type CanisterActor = Types.CanisterActor;
	type CanisterIds = Types.CanisterIds;
	type CanisterInfo = CanisterLedgerTypes.CanisterInfo;

	type Payload = HealthMetricsTypes.Payload;

	let ACTOR_NAME : Text = "CanisterIdsLedger";
	let CANISTER_ID_PROD : Text = "k25dy-3yaaa-aaaag-abcpa-cai";
	let VERSION : Nat = 3;

	var canisters = List.nil<CanisterInfo>();
	stable var canisters_stable_storage : [(CanisterInfo)] = [];

	var authorized : HashMap.HashMap<Text, Text> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var authorized_stable_storage : [(Text, Text)] = [];

	stable var is_prod : Bool = false;

	// ------------------------- CanisterIdsLedger Methods -------------------------
	public shared ({ caller }) func save_canister(canister_child : CanisterInfo) : async Text {
		if (is_prod == false) {
			canisters := List.push<CanisterInfo>(canister_child, canisters);

			return "Added for Dev";
		} else {
			switch (authorized.get(Principal.toText(caller))) {
				case (null) {
					return "Not Authorized";
				};
				case (?principal) {
					canisters := List.push<CanisterInfo>(canister_child, canisters);

					return "Added for Prod";
				};
			};
		};
	};

	// NOTE: only for dev
	public shared ({ caller }) func authorize_ids(ids : [Text]) : async Text {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "authorize_ids")
		];

		let canister_ids_ledger = Principal.fromActor(CanisterIdsLedger);
		let is_production = Text.equal(
			Principal.toText(canister_ids_ledger),
			CANISTER_ID_PROD
		);

		if (authorized.size() > 0) {
			return "already authorized";
		};

		if (is_production == false) {
			for (id in ids.vals()) {
				authorized.put(id, id);
			};

			ignore Logger.log_event(
				tags,
				"authorize_ids"
			);

			return "authorized";
		} else {
			return "is production";
		};
	};

	public query func get_canisters() : async [CanisterInfo] {
		return List.toArray<CanisterInfo>(canisters);
	};

	public query func get_authorized() : async [Text] {
		return Iter.toArray(authorized.vals());
	};

	public query func get_health_metrics_id() : async Text {
		let canister_ids_ledger = Principal.fromActor(CanisterIdsLedger);
		let is_production = Text.equal(
			Principal.toText(canister_ids_ledger),
			CANISTER_ID_PROD
		);

		if (is_production == true) {
			return "ree2h-zaaaa-aaaag-aba5q-cai";
		} else {
			return "txssk-maaaa-aaaaa-aaanq-cai";
		};
	};

	public query func canister_exists(canisterPrincipal : Principal) : async Bool {
		let canisterId : Text = Principal.toText(canisterPrincipal);

		let exists = List.some<CanisterInfo>(
			canisters,
			func(info : CanisterInfo) : Bool {
				return Text.equal(info.id, canisterId);
			}
		);

		return exists;
	};

	// public shared ({ caller }) func drop_canister(n : Nat) : async () {
	//     canisters := List.drop<CanisterInfo>(canisters, n);

	//     return ();
	// };

	// This function logs the health status of multiple canisters by iterating over a list of canister IDs
	// and calling the health() method on the corresponding actor object.
	func log_canisters_health() : async () {
		let all_canister_children = List.toArray<CanisterInfo>(canisters);

		// note: not sure how Iter over records

		for (canister in all_canister_children.vals()) {
			let canister_child_actor = actor (canister.id) : CanisterActor;

			ignore canister_child_actor.health();
		};

		for (canister_id in authorized.vals()) {
			let canister_child_actor = actor (canister_id) : CanisterActor;

			ignore canister_child_actor.health();
		};

		return ();
	};

	// ------------------------- Canister Management Methods -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async () {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("canisters_size", Int.toText(List.size(canisters))),
			("cycles_balance", Int.toText(UtilsShared.get_cycles_balance())),
			("memory_in_mb", Int.toText(UtilsShared.get_memory_in_mb())),
			("heap_in_mb", Int.toText(UtilsShared.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);
	};

	public func start_log_timer() : async Timer.TimerId {

		return Timer.recurringTimer(#seconds(60), log_canisters_health);
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		authorized_stable_storage := Iter.toArray(authorized.entries());

		canisters_stable_storage := List.toArray<CanisterInfo>(canisters);
	};

	system func postupgrade() {
		authorized := HashMap.fromIter<Text, Text>(
			authorized_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		canisters := List.fromArray<CanisterInfo>(canisters_stable_storage);

		authorized_stable_storage := [];
		canisters_stable_storage := [];
	};
};
