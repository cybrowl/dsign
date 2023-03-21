import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import JSON "mo:json/JSON";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor Logger {
	type HeaderField = (Text, Text);

	type HttpRequest = {
		method : Text;
		url : Text;
		headers : [HeaderField];
		body : Blob;
	};

	type HttpResponse = {
		status_code : Nat16;
		headers : [HeaderField];
		body : Blob;
	};

	public type Tags = [(Text, Text)];
	public type Message = Text;
	public type PayloadHealthMetric = {
		metrics : [(Text, Int)];
		name : Text;
		child_canister_id : Text;
		parent_canister_id : Text;
	};

	public type LogEvent = {
		time : Int;
		tags : Tags;
		message : Text;
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

	public shared (msg) func log_event(tags : Tags, message : Message) : async () {
		let log : LogEvent = { time = Time.now(); tags = tags; message = message };

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

	func convert_to_json() : JSON.JSON {
		let logs = Array.map<LogEvent, JSON.JSON>(
			Buffer.toArray(logs_pending),
			func(log : LogEvent) : JSON.JSON {
				return #Object([
					(
						"attributes",
						#Object(
							Array.append(
								Array.map<(Text, Text), (Text, JSON.JSON)>(
									log.tags,
									func(tag : (Text, Text)) : (Text, JSON.JSON) {
										return (tag.0, #String(tag.1));
									}
								),
								[
									("logtype", #String("accesslogs")),
									("hostname", #String("dsign.ooo"))
								]
							)
						)
					),
					("message", #String(log.message)),
					("time", #Number(log.time))
				]);
			}
		);

		let result = #Object([("logs", #Array(logs))]);

		return result;
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
					case ("GET", "/logs") {

						let body = JSON.show(convert_to_json());

						let headers = [("content-type", "application/json")];

						let response : HttpResponse = {
							status_code = 200;
							headers = headers;
							body = Text.encodeUtf8(body);
						};

						return response;
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

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
