// import JSON "mo:json/JSON";
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
	// type HeaderField = (Text, Text);

	// type HttpRequest = {
	//     method : Text;
	//     url : Text;
	//     headers : [HeaderField];
	//     body : Blob;
	// };

	// type HttpResponse = {
	//     body : Blob;
	//     headers : [HeaderField];
	//     status_code : Nat16;
	//     upgrade : Bool;
	// };

	public type Tags = [(Text, Text)];
	public type Message = Text;

	public type LogEvent = {
		time : Int;
		tags : Tags;
		message : Text;
	};

	var logs_storage = Buffer.Buffer<LogEvent>(0);
	var logs_pending = Buffer.Buffer<LogEvent>(0);

	let VERSION : Nat = 1;
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
		let log : LogEvent = { time = Time.now(); tags = tags; message = message };

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

	// public shared (msg) func send_logs_relic() : async () {

	//     let NEW_RELIC_LOG_API_URL = "https://log-api.newrelic.com/log/v1";

	//     let request_headers = [{ name = "Content-Type"; value = "application/json" }, { name = "X-Insert-Key"; value = API_KEY_RELIC }];
	//     let body = JSON.show(convert_to_json());

	//     let request : ICTypes.CanisterHttpRequestArgs = {
	//         url = NEW_RELIC_LOG_API_URL;
	//         headers = request_headers;
	//         body = ?Blob.toArray(Text.encodeUtf8(body));
	//         method = #post;
	//         transform = null;
	//         max_response_bytes = ?2000000;
	//     };

	//     let log : LogEvent = {
	//         time = Time.now();
	//         tags = [];
	//         message = "Before sending logs to New Relic: ";
	//     };

	//     logs_pending.add(log);

	//     Cycles.add(200_500_000_000);
	//     let ic : ICTypes.Self = actor ("aaaaa-aa");
	//     logs_pending.add(log);
	//     let response : ICTypes.CanisterHttpResponsePayload = await ic.http_request(request);

	//     switch (response.status) {
	//         case (200) {
	//             logs_storage.append(logs_pending);
	//             logs_pending.clear();
	//         };
	//         case (status) {
	//             let log : LogEvent = {
	//                 time = Time.now();
	//                 tags = [];
	//                 message = "Error sending logs to New Relic: " # Int.toText(status) # " " # debug_show (response.body);
	//             };
	//             logs_pending.add(log);
	//         };
	//     };
	// };

	// public func start_log_timer() : async Timer.TimerId {
	//     return Timer.recurringTimer(#seconds(60), send_logs_relic);
	// };

	// func convert_to_json() : JSON.JSON {
	//     let logs = Array.map<LogEvent, JSON.JSON>(
	//         Buffer.toArray(logs_pending),
	//         func(log : LogEvent) : JSON.JSON {
	//             return #Object([
	//                 (
	//                     "attributes",
	//                     #Object(
	//                         Array.append(
	//                             Array.map<(Text, Text), (Text, JSON.JSON)>(
	//                                 log.tags,
	//                                 func(tag : (Text, Text)) : (Text, JSON.JSON) {
	//                                     return (tag.0, #String(tag.1));
	//                                 }
	//                             ),
	//                             [
	//                                 ("logtype", #String("accesslogs")),
	//                                 ("hostname", #String("dsign.ooo"))
	//                             ]
	//                         )
	//                     )
	//                 ),
	//                 ("message", #String(log.message)),
	//                 ("time", #Number(log.time))
	//             ]);
	//         }
	//     );

	//     let result = #Array(logs);

	//     return result;
	// };

	// ------------------------- HTTP -------------------------
	// public query func http_request(req : HttpRequest) : async HttpResponse {
	//     if ((req.method, req.url) == ("GET", "/logs")) {
	//         let body = JSON.show(convert_to_json());
	//         let headers = [("content-type", "application/json")];

	//         {
	//             body = Text.encodeUtf8(body);
	//             headers = headers;
	//             status_code = 200;
	//             upgrade = false;
	//         };
	//     } else {
	//         {
	//             body = Text.encodeUtf8("Invalid request");
	//             headers = [];
	//             status_code = 400;
	//             upgrade = false;
	//         };
	//     };
	// };

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared ({ caller }) func whoami() : async Text {
		return Principal.toText(caller);
	};
};
