import B "mo:base/Buffer";
import Types "./types";

actor Logger = {
    type Log = Types.Log;

    var logs = B.Buffer<Log>(2);

    public query func ping() : async Text {
        return "meow";
    };

    public shared (msg) func log_event(log: Log) : async () {
        logs.add(log);
    };

    public query func get_logs() : async [Log] {
        return logs.toArray();
    };
};
