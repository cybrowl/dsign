import { Buffer; toArray; fromArray } "mo:base/Buffer";
import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import ICTypes "../c_types/ic";
import Types "./types";

import Arr "../libs/array";
import Health "../libs/health";

actor Logger {
	let { thash } = Map;

	type AuthorizationError = { #NotAuthorized : Bool };
	type CanisterInfo = Types.CanisterInfo;
	type ICManagementActor = ICTypes.Self;
	type LogEvent = Types.LogEvent;
	type Message = Types.Message;
	type Tags = Types.Tags;

	type CanisterActor = Types.CanisterActor;

	// ------------------------- Variables -------------------------
	let VERSION : Nat = 7;
	let ACTOR_NAME : Text = "Logger";
	stable var authorized : ?Principal = null;

	// ------------------------- Storage Data -------------------------
	var logs_storage = Buffer<LogEvent>(0);
	stable var logs_storage_stable_storage : [LogEvent] = [];

	var logs_pending = Buffer<LogEvent>(0);
	stable var logs_pending_stable_storage : [LogEvent] = [];

	private var canister_registry = Map.new<Text, Text>();
	stable var canister_registry_stable_storage : [(Text, Text)] = [];

	// ------------------------- Actor -------------------------
	private let ic_management_actor : ICManagementActor = actor "aaaaa-aa";

	// ------------------------- Logger -------------------------
	public shared ({ caller }) func authorize() : async Bool {
		switch (authorized) {
			case (?authorized) {

				return true;
			};
			case (null) {
				authorized := ?caller;

				return false;
			};
		};
	};

	public shared func log_event(tags : Tags, message : Message) : async () {
		//TODO: gate this func with some auth

		let logger_principal = Principal.fromActor(Logger);

		var env = "local";

		// Note: change me to your canister id
		switch (Principal.toText(logger_principal)) {
			case ("jaypp-oiaaa-aaaag-aaa6q-cai") {
				env := "prod";
			};
			case ("patve-6yaaa-aaaag-ak2mq-cai") {
				env := "staging";
			};
			case _ {
				env := "local";
			};
		};

		let log : LogEvent = {
			hostname = "dsign.ooo";
			logtype = "accesslogs";
			env = env;
			message = message;
			tags = tags;
			time = Time.now();
		};

		logs_pending.add(log);
	};

	public shared ({ caller }) func clear_logs() : async Result.Result<Text, AuthorizationError> {
		switch (authorized == ?caller) {
			case (true) {
				logs_storage.append(logs_pending);
				logs_pending.clear();

				return #ok("Logs cleared");
			};
			case (false) {
				return #err(#NotAuthorized(true));
			};
		};
	};

	public shared ({ caller }) func add_canister_id_to_registry(canister_ids : [Text]) : async Bool {
		let explore : [Text] = ["kjp6m-uyaaa-aaaag-ak2qq-cai", "phstq-taaaa-aaaag-ak2ma-cai"];
		let file_scaling_manager : [Text] = ["k4ipb-vqaaa-aaaag-ak2ta-cai", "pvuej-7qaaa-aaaag-ak2pa-cai"];
		let mo : [Text] = ["kamvq-cqaaa-aaaag-ak2ra-cai", "pjq6y-iqaaa-aaaag-ak2na-cai"];
		let username_registry : [Text] = ["khnte-piaaa-aaaag-ak2rq-cai", "porym-fiaaa-aaaag-ak2nq-cai"];

		let canisters : [Text] = Array.flatten([explore, file_scaling_manager, mo, username_registry]);

		let is_authorized = Arr.exists<Text>(
			canisters,
			func(canister_id) : Bool {
				canister_id == Principal.toText(caller);
			}
		);

		if (is_authorized) {
			for (canister_id in canister_ids.vals()) {
				ignore Map.put(canister_registry, thash, canister_id, canister_id);

			};
			return true;
		};

		return false;
	};

	public query ({ caller }) func get_logs() : async Result.Result<[LogEvent], AuthorizationError> {
		if (authorized == ?caller) {
			return #ok(toArray(logs_pending));
		} else {
			return #err(#NotAuthorized(true));
		};
	};

	public query func size() : async Nat {
		return logs_pending.size();
	};

	// ------------------------- Canister Management -------------------------
	// Version
	public query func version() : async Nat {
		return VERSION;
	};

	// Get Registry
	public query func get_registry() : async [Text] {
		return Iter.toArray(Map.vals(canister_registry));
	};

	// Init
	public shared func init() : async () {
		let logger_cid : Text = Principal.toText(Principal.fromActor(Logger));

		ignore Map.put(canister_registry, thash, logger_cid, logger_cid);
	};

	public shared ({ caller }) func whoami() : async Text {
		return Principal.toText(caller);
	};

	public shared func health() : async () {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("version", Int.toText(VERSION)),
			("logs_pending_size", Int.toText(logs_pending.size())),
			("logs_storage_size", Int.toText(logs_storage.size())),
			("cycles_balance", Int.toText(Health.get_cycles_balance())),
			("memory_in_mb", Int.toText(Health.get_memory_in_mb())),
			("heap_in_mb", Int.toText(Health.get_heap_in_mb()))
		];

		ignore log_event(
			tags,
			"health"
		);

		return ();
	};

	public query func cycles_low() : async Bool {
		return Health.get_cycles_low();
	};

	private func log_canisters_health() : async () {
		for (canister_id in Map.vals(canister_registry)) {
			let canister_actor = actor (canister_id) : CanisterActor;

			ignore canister_actor.health();
		};

		return ();
	};

	private func check_cycles() : async () {
		for (canister_id in Map.vals(canister_registry)) {
			let canister_actor = actor (canister_id) : CanisterActor;

			switch (await canister_actor.cycles_low()) {
				case (true) {

					Cycles.add<system>(1_000_000_000_000);
					await ic_management_actor.deposit_cycles({
						canister_id = Principal.fromText(canister_id);
					});
				};
				case (false) {};
			};
		};

		return ();
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		logs_storage_stable_storage := toArray(logs_storage);
		logs_pending_stable_storage := toArray(logs_pending);

		canister_registry_stable_storage := Iter.toArray(Map.entries(canister_registry));
	};

	system func postupgrade() {
		logs_storage := fromArray(logs_storage_stable_storage);
		logs_storage_stable_storage := [];

		logs_pending := fromArray(logs_pending_stable_storage);
		logs_pending_stable_storage := [];

		canister_registry := Map.fromIter<Text, Text>(canister_registry_stable_storage.vals(), thash);
		canister_registry_stable_storage := [];

		ignore Timer.recurringTimer<system>(#seconds(60), log_canisters_health);
		ignore Timer.recurringTimer<system>(#seconds(300), check_cycles);
	};
};
