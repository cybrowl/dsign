import { Buffer; toArray; fromArray; subBuffer } "mo:base/Buffer";
import Blob "mo:base/Blob";
import Buff "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import JSON "mo:json/JSON";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import StableMemory "mo:base/ExperimentalStableMemory";
import Text "mo:base/Text";
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

	public type LogMin = {
		id : Text;
		time : Int;
		name : Text;
		heap_in_mb : Int;
		memory_in_mb : Int;
		cycles_balance : Int;
	};

	type HeaderField = (Text, Text);

	type HttpResponse = {
		status_code : Nat16;
		headers : [HeaderField];
		body : Blob;
	};

	type HttpRequest = {
		method : Text;
		url : Text;
		headers : [HeaderField];
		body : Blob;
	};

	type Metrics = {
		balance : {
			help : Text;
			value : Text;
			timestamp : Text;
		};
		heap_size : {
			help : Text;
			value : Text;
			timestamp : Text;
		};
	};

	var logs_unique = HashMap.HashMap<Text, LogMin>(
		0,
		Text.equal,
		Text.hash
	);
	stable var logs_unique_stable_storage : [(Text, LogMin)] = [];

	var logs_ordered = HashMap.HashMap<Text, [Log]>(
		0,
		Text.equal,
		Text.hash
	);
	stable var logs_ordered_stable_storage : [(Text, [Log])] = [];

	let ACTOR_NAME : Text = "HealthMetrics";
	let VERSION : Nat = 4;

	public shared (msg) func log_event(log_payload : Payload) : async () {
		// TODO: some auth check here

		let log = {
			time = Time.now();
			child_canister_id = log_payload.child_canister_id;
			parent_canister_id = log_payload.parent_canister_id;
			name = log_payload.name;
			metrics = log_payload.metrics;
		};

		let log_min = {
			id = log_payload.child_canister_id;
			time = log.time;
			name = log.name;
			cycles_balance = log_payload.metrics[1].1;
			memory_in_mb = log_payload.metrics[2].1;
			heap_in_mb = log_payload.metrics[3].1;
		};

		logs_unique.put(log_payload.child_canister_id, log_min);

		switch (logs_ordered.get(log_payload.child_canister_id)) {
			case null {
				var logs_buffer = Buffer<Log>(0);
				logs_buffer.add(log);
				logs_ordered.put(log_payload.child_canister_id, toArray(logs_buffer));
			};
			case (?logs) {
				var logs_buffer : Buff.Buffer<Log> = fromArray(logs);
				logs_buffer.add(log);
				logs_ordered.put(log_payload.child_canister_id, toArray(logs_buffer));
			};
		};
	};

	public query func get_unique_logs() : async [LogMin] {
		return Iter.toArray(logs_unique.vals());
	};

	public query func get_canister_logs(id : Text) : async ?[Log] {
		switch (logs_ordered.get(id)) {
			case null {
				return null;
			};
			case (?logs) {
				return ?logs;
			};
		};
	};

	// ------------------------- HTTP -------------------------
	public query func http_request(req : HttpRequest) : async HttpResponse {
		let path = Text.split(req.url, #char '?').next();

		switch (path) {
			case (null) {
				{
					status_code = 400;
					headers = [];
					body = "Path Invalid";
				};
			};
			case (?path) {
				switch (req.method, path) {
					// Endpoint that serves metrics to be consumed with Prometheseus
					case ("GET", "/metrics") {

						let m = JSON.show(metrics());

						{
							status_code = 200;
							headers = [("content-type", "application/json")];
							body = Text.encodeUtf8(m);
						};
					};
					case _ {
						{
							status_code = 400;
							headers = [];
							body = "Invalid request";
						};
					};
				};
			};
		};

	};

	func metrics() : JSON.JSON {
		// Prometheus expects timestamps in ms. Time.now() returns ns.
		let timestamp = Int.toText(Time.now() / 1000000);

		let metrics : JSON.JSON = #Object([
			("balance", #Object([("help", #String("The current balance in cycles")), ("timestamp", #String(timestamp)), ("value", #String(Nat.toText(Cycles.balance())))])),
			("heap_size", #Object([("help", #String("The current size of the wasm heap in pages of 64KiB")), ("timestamp", #String(timestamp)), ("value", #String(Nat.toText(Prim.rts_heap_size())))]))
		]);

		return metrics;
	};
	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let log_payload : Payload = {
			metrics = [
				("logs_ordered_size", logs_ordered.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(HealthMetrics));
			parent_canister_id = "";
		};

		return log_payload;
	};

	// ------------------------- SYSTEM METHODS -------------------------
	system func preupgrade() {
		logs_unique_stable_storage := Iter.toArray(logs_unique.entries());

		logs_ordered_stable_storage := Iter.toArray(logs_ordered.entries());
	};

	system func postupgrade() {
		logs_unique := HashMap.fromIter<Text, LogMin>(
			logs_unique_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);

		logs_unique_stable_storage := [];

		logs_ordered := HashMap.fromIter<Text, [Log]>(
			logs_ordered_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		logs_ordered_stable_storage := [];
	};
};
