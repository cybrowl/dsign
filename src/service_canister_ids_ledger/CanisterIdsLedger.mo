import { Buffer; toArray } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

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
	let VERSION : Nat = 1;

	var canisters = List.nil<CanisterInfo>();
	stable var canisters_stable_storage : [(CanisterInfo)] = [];

	var authorized : HashMap.HashMap<Text, Text> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var authorized_stable_storage : [(Text, Text)] = [];

	stable var is_prod : Bool = false;

	stable var canister_ids : CanisterIds = {
		explore = "72zia-7aaaa-aaaag-aa37a-cai";
		favorite_main = "a7b5k-xiaaa-aaaag-aa6ja-cai";
		profile = "kxkd5-7qaaa-aaaag-aaawa-cai";
		project_main = "nhlnj-vyaaa-aaaag-aay5q-cai";
		snap_main = "lyswl-7iaaa-aaaag-aatya-cai";
	};

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

	public query func get_canisters() : async [CanisterInfo] {
		return List.toArray<CanisterInfo>(canisters);
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

	public query func get_canister_ids() : async CanisterIds {
		return canister_ids;
	};

	// public shared ({ caller }) func drop_canister(n : Nat) : async () {
	// 	canisters := List.drop<CanisterInfo>(canisters, n);

	// 	return ();
	// };

	public shared ({ caller }) func set_canister_ids(canisterIds : CanisterIds) : async Text {
		let canister_ids_ledger = Principal.fromActor(CanisterIdsLedger);
		let is_production = Text.equal(
			Principal.toText(canister_ids_ledger),
			CANISTER_ID_PROD
		);

		if (is_production == false) {
			canister_ids := canisterIds;

			return debug_show ("set", canister_ids);

		} else {
			return "is production";
		};
	};

	public shared ({ caller }) func log_canisters_health() : async Text {
		let all_canister_children = List.toArray<CanisterInfo>(canisters);

		// note: not sure how Iter over records
		let canister_ids_arr = [
			canister_ids.explore,
			canister_ids.favorite_main,
			canister_ids.profile,
			canister_ids.project_main,
			canister_ids.snap_main
		];

		for (canister in all_canister_children.vals()) {
			let canister_child_actor = actor (canister.id) : CanisterActor;

			ignore canister_child_actor.health();
		};

		for (canister_id in canister_ids_arr.vals()) {
			let canister_child_actor = actor (canister_id) : CanisterActor;

			ignore canister_child_actor.health();
		};

		return "ok";
	};

	public shared func initialize_authorized_principals() : async Text {
		let canister_ids_ledger = Principal.fromActor(CanisterIdsLedger);
		let is_production = Text.equal(
			Principal.toText(canister_ids_ledger),
			CANISTER_ID_PROD
		);

		is_prod := is_production;

		let author : Text = "ru737-xk264-4nswf-o6lzb-3juxx-ixp63-objgb-l4io2-yievs-5ezxe-kqe";
		let favorite_main : Text = "a7b5k-xiaaa-aaaag-aa6ja-cai";
		let profile : Text = "kxkd5-7qaaa-aaaag-aaawa-cai";
		let project_main : Text = "nhlnj-vyaaa-aaaag-aay5q-cai";
		let snap_main : Text = "lyswl-7iaaa-aaaag-aatya-cai";

		if (authorized.size() < 5) {
			authorized.put(author, author);
			authorized.put(favorite_main, favorite_main);
			authorized.put(profile, profile);
			authorized.put(project_main, project_main);
			authorized.put(snap_main, snap_main);

			return "added";
		} else {
			return "exists";
		}

	};

	// ------------------------- Canister Management Methods -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let log_payload : Payload = {
			metrics = [
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(CanisterIdsLedger));
			parent_canister_id = "";
		};

		return log_payload;
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