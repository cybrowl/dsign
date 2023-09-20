import { Buffer; toArray } "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
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
import ICTypes "../types/ic.types";

import UtilsShared "../utils/utils";

actor CanisterIdsLedger = {
	type CanisterActor = Types.CanisterActor;
	type LoggerActor = Types.LoggerActor;

	type CanisterIds = Types.CanisterIds;
	type CanisterInfo = CanisterLedgerTypes.CanisterInfo;

	type Payload = HealthMetricsTypes.Payload;

	let ACTOR_NAME : Text = "CanisterIdsLedger";
	let CANISTER_ID_PROD : Text = "k25dy-3yaaa-aaaag-abcpa-cai";
	let CANISTER_ID_STAGING : Text = "etfrh-saaaa-aaaag-abqha-cai";
	let VERSION : Nat = 6;

	var canisters = List.nil<CanisterInfo>();
	stable var canisters_stable_storage : [(CanisterInfo)] = [];

	var authorized : HashMap.HashMap<Text, Text> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var authorized_stable_storage : [(Text, Text)] = [];

	stable var is_prod : Bool = false;
	stable var timer_id : Nat = 0;

	stable var logger_canister_id : Text = "jaypp-oiaaa-aaaag-aaa6q-cai";
	let ic : ICTypes.Self = actor ("aaaaa-aa");

	// ------------------------- CanisterIdsLedger Methods -------------------------
	public shared ({ caller }) func save_canister(canister_child : CanisterInfo) : async Text {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "save_canister")
		];

		let caller_ : Text = Principal.toText(caller);

		// check if canister exists before adding
		let canister_exists = List.some<CanisterInfo>(
			canisters,
			func(info : CanisterInfo) : Bool {
				return Text.equal(info.id, canister_child.id);
			}
		);

		if (canister_exists == true) {
			return "Canister already exists";
		};

		switch (authorized.get(caller_)) {
			case (null) {
				return "Not Authorized: " # caller_;
			};
			case (?principal) {
				canisters := List.push<CanisterInfo>(canister_child, canisters);

				return "Added Canister";
			};
		};
	};

	// NOTE: only for dev
	public shared ({ caller }) func authorize_ids(ids : [Text]) : async Text {
		let is_production = Text.equal(
			Principal.toText(Principal.fromActor(CanisterIdsLedger)),
			CANISTER_ID_PROD
		);

		let is_staging = Text.equal(
			Principal.toText(Principal.fromActor(CanisterIdsLedger)),
			CANISTER_ID_STAGING
		);

		if (is_production == true or is_staging == true) {
			return "Try Dev";
		};

		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "authorize_ids")
		];

		for (id in ids.vals()) {
			authorized.put(id, id);
		};

		return "authorized";
	};

	// NOTE: only for dev
	public shared ({ caller }) func set_logger_id(id : Text) : async Text {
		let is_production = Text.equal(
			Principal.toText(Principal.fromActor(CanisterIdsLedger)),
			CANISTER_ID_PROD
		);

		let is_staging = Text.equal(
			Principal.toText(Principal.fromActor(CanisterIdsLedger)),
			CANISTER_ID_STAGING
		);

		if (is_production == true or is_staging == true) {
			return "Try Dev";
		};

		logger_canister_id := id;

		return logger_canister_id;
	};

	public query func get_canisters() : async [CanisterInfo] {
		return List.toArray<CanisterInfo>(canisters);
	};

	public query func get_authorized() : async [Text] {
		return Iter.toArray(authorized.vals());
	};

	public query func canister_exists(id : Text) : async Bool {
		let exists = List.some<CanisterInfo>(
			canisters,
			func(info : CanisterInfo) : Bool {
				return Text.equal(info.id, id);
			}
		);

		return exists;
	};

	// This function logs the health status of multiple canisters by iterating over a list of canister IDs
	// and calling the health() method on the corresponding actor object.
	func log_canisters_health() : async () {
		let all_canisters = List.toArray<CanisterInfo>(canisters);

		for (canister in all_canisters.vals()) {
			let canister_actor = actor (canister.id) : CanisterActor;

			ignore canister_actor.health();
		};

		return ();
	};

	func trigger_logs_cron() : async () {
		let url = "https://new-relic-logger.vercel.app/api/cron";
		let request_headers = [{ name = "User-Agent"; value = "logs_canister" }];
		let http_request : ICTypes.CanisterHttpRequestArgs = {
			url = url;
			max_response_bytes = null;
			headers = request_headers;
			body = null;
			method = #get;
			transform = null;
		};

		ignore ic.http_request(http_request);
	};

	func check_cycles() : async () {
		let all_canisters = List.toArray<CanisterInfo>(canisters);

		for (canister in all_canisters.vals()) {
			let canister_actor = actor (canister.id) : CanisterActor;

			switch (await canister_actor.cycles_low()) {
				case (true) {

					Cycles.add(1_000_000_000_000);
					await ic.deposit_cycles({ canister_id = Principal.fromText(canister.id) });
				};
				case (false) {};
			};
		};

		return ();
	};

	// ------------------------- Canister Management Methods -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public query func get_timer_id() : async Nat {
		return timer_id;
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

		let logger_actor = actor (logger_canister_id) : LoggerActor;

		ignore logger_actor.log_event(tags, "health");
	};

	public query func cycles_low() : async Bool {
		return UtilsShared.get_cycles_low();
	};

	public shared func health_manual() : async () {
		ignore log_canisters_health();
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

		ignore Timer.recurringTimer(#seconds(60), log_canisters_health);
		ignore Timer.recurringTimer(#seconds(120), check_cycles);
		// ignore Timer.recurringTimer(#seconds(120), trigger_logs_cron);

		authorized_stable_storage := [];
		canisters_stable_storage := [];
	};
};
