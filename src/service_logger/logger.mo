import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import ICTypes "../types/ic.types";

actor Logger {
	public type Tags = [(Text, Text)];
	public type Message = Text;

	public type LogEvent = {
		hostname : Text;
		logtype : Text;
		env : Text;
		message : Text;
		tags : Tags;
		time : Int;
	};

	var logs_storage = Buffer.Buffer<LogEvent>(0);
	var logs_pending = Buffer.Buffer<LogEvent>(0);

	let VERSION : Nat = 2;
	stable var authorized : ?Principal = null;

	public shared ({ caller }) func authorize() : async Bool {
		switch (authorized) {
			case (?authorized) {
				assert (authorized == caller);

				return true;
			};
			case (null) {
				authorized := ?caller;

				return false;
			};
		};
	};

	public shared (msg) func log_event(tags : Tags, message : Message) : async () {
		//TODO: lock it for only authorized canisters
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

	public shared ({ caller }) func clear_logs() : async Text {
		assert (authorized == ?caller);

		logs_storage.append(logs_pending);
		logs_pending.clear();

		return "Logs cleared";
	};

	public query ({ caller }) func get_logs() : async [LogEvent] {
		assert (authorized == ?caller);

		return Buffer.toArray(logs_pending);
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared ({ caller }) func whoami() : async Text {
		return Principal.toText(caller);
	};
};
