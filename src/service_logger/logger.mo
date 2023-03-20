import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor Logger {
	public type Tags = [Text];
	public type Payload = Text;
	public type PayloadHealthMetric = {
		metrics : [(Text, Int)];
		name : Text;
		child_canister_id : Text;
		parent_canister_id : Text;
	};

	public type LogEvent = {
		time : Int;
		tags : Tags;
		payload : Text;
	};
	public type LogHealthMetric = {
		child_canister_id : Text;
		metrics : [(Text, Int)];
		name : Text;
		parent_canister_id : Text;
		time : Int;
	};

	var logs_storage = Buffer.Buffer<LogEvent>(0);
	var logs_pending = Buffer.Buffer<LogEvent>(0);
	var logs_health_metric_pending = Buffer.Buffer<LogHealthMetric>(0);

	let VERSION : Nat = 1;

	public shared (msg) func log_event(tags : Tags, payload : Payload) : async () {
		let log : LogEvent = { time = Time.now(); tags = tags; payload = "" };

		logs_pending.add(log);
	};

	public shared (msg) func log_health_metric(tags : Tags, payload : PayloadHealthMetric) : async () {
		let log : LogHealthMetric = {
			child_canister_id = payload.child_canister_id;
			metrics = payload.metrics;
			name = payload.name;
			parent_canister_id = payload.parent_canister_id;
			time = Time.now();
		};

		logs_health_metric_pending.add(log);
	};

	public query func get_logs() : async [LogEvent] {
		return Buffer.toArray(logs_pending);
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
