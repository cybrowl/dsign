import { Buffer; toArray; fromArray; subBuffer } "mo:base/Buffer";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

import UtilsShared "../utils/utils";

actor HealthMetrics = {
	public type Payload = {
		metrics : [(Text, Int)];
		name : Text;
		child_canister_id : Text;
		parent_canister_id : Text;
	};

	public type Log = {
		metrics : [(Text, Int)];
		name : Text;
		child_canister_id : Text;
		parent_canister_id : Text;
		time : Int;
	};

	var logs = Buffer<Log>(0);
	stable var logs_stable_storage : [(Log)] = [];

	let ACTOR_NAME : Text = "HealthMetrics";
	let CYCLE_AMOUNT : Nat = 100_000_0000_000;
	let VERSION : Nat = 1;

	// note: only called from app canisters
	public shared (msg) func log_event(log_payload : Payload) : async () {
		// TODO: some auth check here

		let log = {
			time = Time.now();
			child_canister_id = log_payload.child_canister_id;
			parent_canister_id = log_payload.parent_canister_id;
			name = log_payload.name;
			metrics = log_payload.metrics;
		};

		logs.add(log);
	};

	public query func get_logs() : async [Log] {
		//NOTE: to be deprecated once we have a better way to get logs
		return toArray(logs);
	};

	public query func get_latest_logs(length : Nat) : async [Log] {
		let logs_length = logs.size();
		let start_index : Nat = logs_length - length;

		let latest_logs = subBuffer(logs, start_index, length);

		return toArray(latest_logs);
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let log_payload : Payload = {
			metrics = [
				("logs_num", logs.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(HealthMetrics));
			parent_canister_id = "";
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
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
