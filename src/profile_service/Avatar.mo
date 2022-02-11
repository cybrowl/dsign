import Text "mo:base/Text";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";

import Logger "canister:logger";
import Utils "./utils";
import Types "./types";

actor Avatar = {
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;
    type Image = Types.Image;
    type Username = Text;

    let ACTOR_NAME : Text = "Avatar";
    let MAX_BYTES = 2_000_000;

    var avatars : HashMap.HashMap<Username, Image> = HashMap.HashMap(1, Text.equal, Text.hash);

    public query func ping() : async Text {
        return "meow";
    };

    public shared func set(avatar: Image, username: Username) : async () {
        if (avatar.content.size() > MAX_BYTES) {
            return ();
        };

        avatars.put(username, avatar);
    };

    public shared query func http_request(req : HttpRequest) : async HttpResponse {
        let username : Text = Utils.get_username(req.url);
        let NOT_FOUND : Blob = "Not Found";

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
