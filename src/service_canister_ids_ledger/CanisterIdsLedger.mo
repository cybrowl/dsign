import { Buffer; toArray } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CanisterLedgerTypes "../types/canidster_ids_ledger.types";
import Types "./types";

import Logger "canister:logger";

actor CanisterChildLedger = {
	type CanisterActor = Types.CanisterActor;
	type CanisterIds = Types.CanisterIds;
	type CanisterInfo = CanisterLedgerTypes.CanisterInfo;

	let ACTOR_NAME : Text = "CanisterChildLedger";

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

	public query func ping() : async Text {
		return "meow";
	};

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
		let canister_child_ledger = Principal.fromActor(CanisterChildLedger);
		let is_production = Text.equal(
			Principal.toText(canister_child_ledger),
			"7t2d4-jiaaa-aaaag-aa36q-cai"
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

	public shared ({ caller }) func set_canister_ids(canisterIds : CanisterIds) : async Text {
		let canister_child_ledger = Principal.fromActor(CanisterChildLedger);
		let is_production = Text.equal(
			Principal.toText(canister_child_ledger),
			"7t2d4-jiaaa-aaaag-aa36q-cai"
		);

		if (is_production == false) {
			canister_ids := canisterIds;

			return debug_show ("set", canister_ids);

		} else {
			return "is production";
		};
	};

	public shared ({ caller }) func call_health() : async Text {
		let tags = [ACTOR_NAME, "call_health"];

		let all_canister_children = List.toArray<CanisterInfo>(canisters);

		for (canister in all_canister_children.vals()) {
			switch (canister.name) {
				case ("snap") {

					ignore Logger.log_event(
						tags,
						"snap"
					);

					let canister_child_actor = actor (canister.id) : CanisterActor;

					ignore canister_child_actor.health();
				};
				case (_) {
					// ignore
				};
			};
		};

		return "ok";
	};

	public shared func initialize_authorized_principals() : async Text {
		let canister_child_ledger = Principal.fromActor(CanisterChildLedger);
		let is_production = Text.equal(
			Principal.toText(canister_child_ledger),
			"7t2d4-jiaaa-aaaag-aa36q-cai"
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

	// ------------------------- SYSTEM METHODS -------------------------
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
