import Debug "mo:base/Debug";
import Text "mo:base/Text";

module {
    public func get_username(url: Text): Text {
        switch (Text.split(url, #char '&').next()) {
            // check user exists
            case (?string) {
                string
            };
            case (null) {
                return ""
            };
        };
    };
}