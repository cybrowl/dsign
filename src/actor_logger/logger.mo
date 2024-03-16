import { Buffer; toArray; fromArray } "mo:base/Buffer";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";

import Health "../libs/health";

actor Logger {
	public type Tags = [(Text, Text)];
	public type Message = Text;
	type CanisterInfo = Types.CanisterInfo;

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

	let VERSION : Nat = 5;
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

	public shared func log_event(tags : Tags, message : Message) : async () {
		//TODO: gate this func with some auth

		let logger_principal = Principal.fromActor(Logger);

		var env = "dev";

		// Note: change me to your canister id
		switch (Principal.toText(logger_principal)) {
			case ("jaypp-oiaaa-aaaag-aaa6q-cai") {
				env := "prod";
			};
			case ("goy7p-biaaa-aaaag-abqiq-cai") {
				env := "staging";
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

	public query ({}) func size() : async Nat {
		return logs_pending.size();
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
