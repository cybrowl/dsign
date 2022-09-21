import B "mo:base/Buffer";
import Time "mo:base/Time";
import Types "./types";

actor Logger = {
	type Tags = Types.Tags;
	type Payload = Types.Payload;
	type Log = Types.Log;

	var logs = B.Buffer<Log>(2);

	public query func ping() : async Text {
		return "meow";
	};

	public shared (msg) func log_event(tags : Tags, payload : Payload) : async () {
		var mutableLog : Log = { time = Time.now(); tags = tags; payload = "" };

		if (payload.size() > 0) {
			mutableLog := { time = Time.now(); tags = tags; payload = payload };
		};

		logs.add(mutableLog);
	};

	public query func get_logs() : async [Log] {
		return logs.toArray();
	};
};
