import Array "mo:base/Array";
import Blob "mo:base/Blob";
import { Buffer; toArray; fromArray } "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Result "mo:base/Result";

import CanisterIdsLedger "canister:canister_ids_ledger";

import ICTypes "../types/ic.types";
import CanisterLedgerTypes "../types/canidster_ids_ledger.types";

import UtilsShared "../utils/utils";

actor Logger {
	public type Tags = [(Text, Text)];
	public type Message = Text;
	type CanisterInfo = CanisterLedgerTypes.CanisterInfo;

	type AuthorizationError = { #NotAuthorized : Bool };

	public type LogEvent = {
		hostname : Text;
		logtype : Text;
		env : Text;
		message : Text;
		tags : Tags;
		time : Int;
	};

	var logs_storage = Buffer<LogEvent>(0);
	stable var logs_storage_stable_storage : [LogEvent] = [];

	var logs_pending = Buffer<LogEvent>(0);
	stable var logs_pending_stable_storage : [LogEvent] = [];

	let VERSION : Nat = 4;
	let ACTOR_NAME : Text = "Logger";

	stable var authorized : ?Principal = null;

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

	public shared ({ caller }) func log_event(tags : Tags, message : Message) : async () {
		let authorized = await CanisterIdsLedger.canister_exists(Principal.toText(caller));

		if (authorized == false) {
			return ();
		};

		let profile_principal = Principal.fromActor(Logger);

		var env = "dev";

		// Note: change me to your canister id
		switch (Principal.toText(profile_principal)) {
			case ("jaypp-oiaaa-aaaag-aaa6q-cai") {
				env := "prod";
			};
			case _ {
				env := "dev";
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

	public query ({ caller }) func get_logs() : async Result.Result<[LogEvent], AuthorizationError> {
		if (authorized == ?caller) {
			return #ok(toArray(logs_pending));
		} else {
			return #err(#NotAuthorized(true));
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared ({ caller }) func whoami() : async Text {
		return Principal.toText(caller);
	};

	public shared func health() : async () {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("logs_pending_size", Int.toText(logs_pending.size())),
			("logs_storage_size", Int.toText(logs_storage.size())),
			("cycles_balance", Int.toText(UtilsShared.get_cycles_balance())),
			("memory_in_mb", Int.toText(UtilsShared.get_memory_in_mb())),
			("heap_in_mb", Int.toText(UtilsShared.get_heap_in_mb()))
		];

		ignore log_event(
			tags,
			"health"
		);

		return ();
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		logs_storage_stable_storage := toArray(logs_storage);
		logs_pending_stable_storage := toArray(logs_pending);
	};

	system func postupgrade() {
		logs_storage := fromArray(logs_storage_stable_storage);
		logs_pending := fromArray(logs_pending_stable_storage);
	};
};
