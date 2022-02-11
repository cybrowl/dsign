import Text "mo:base/Text";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";

import Logger "canister:logger";
import Types "./types";

actor ProfileAvatar = {
    let ACTOR_NAME : Text = "ProfileAvatar";
    
    type Image = {
        content: Blob
    };

    type Username = Text;

    var avatars : HashMap.HashMap<Username, Image> = HashMap.HashMap(1, Text.equal, Text.hash);

    public query func ping() : async Text {
        return "meow";
    };

    public shared func save(image: Image, username: Username) : async () {
        avatars.put(username, image);

        Debug.print(debug_show(("added")));

    };

    public shared query func http_request(req : Types.HttpRequest) : async Types.HttpResponse {
        Debug.print(debug_show(("url", req.url)));
        Debug.print(debug_show(("method", req.method)));

        let username : Text = "mishi";
        let NOT_FOUND : Blob = "Not Found";

        let correctPath : Bool = Text.contains(req.url, #text "/avatar/");

        if (correctPath == false) {
            return {
                status_code = 404;
                headers = [ ("content-type", "image/png") ];
                body = NOT_FOUND;
            };
        };

        switch (avatars.get(username)) {
            case (?image) {
                return {
                    status_code = 200;
                    headers = [ ("content-type", "image/png") ];
                    body = image.content;
                };
            };
            case (null) {
                return {
                    status_code = 404;
                    headers = [ ("content-type", "image/png") ];
                    body = NOT_FOUND;
                };
            };
        };
    };
};
