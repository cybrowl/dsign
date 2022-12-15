import { Buffer; toArray; fromArray } "mo:base/Buffer";
import Iter "mo:base/Iter";
import Time "mo:base/Time";

actor HealthMetrics = {
	public type Payload = {
		metrics : [(Text, Int)];
		name : Text;
		parent_canister_id : Text;
	};

	public type Log = {
		metrics : [(Text, Int)];
		name : Text;
		parent_canister_id : Text;
		time : Int;
	};

	var logs = Buffer<Log>(0);
	stable var logs_stable_storage : [(Log)] = [];

	let ACTOR_NAME : Text = "HealthMetrics";
	let CYCLE_AMOUNT : Nat = 100_000_0000_000;
	let VERSION : Nat = 1;

	public shared (msg) func log_event(log_payload : Payload) : async () {
		var log : Log = { time = Time.now(); parent_canister_id = ""; name = ""; metrics = [] };

		if (log.metrics.size() > 0) {
			log := {
				time = Time.now();
				parent_canister_id = log_payload.parent_canister_id;
				name = log_payload.name;
				metrics = log_payload.metrics;
			};
		};

		logs.add(log);
	};

	public query func get_logs() : async [Log] {
		return toArray(logs);
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		logs_stable_storage := toArray(logs);
	};

	system func postupgrade() {
		logs := fromArray(logs_stable_storage);
		logs_stable_storage := [];
	};
};
