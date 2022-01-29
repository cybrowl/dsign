import Int "mo:base/Int";
import Text "mo:base/Text";

module {
    public type Log = {
        time: Int;
        tags: [Text];
        payload: Text;
    };
};

