import Debug "mo:base/Debug";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Text "mo:base/Text";

import Logger "canister:logger";
import Utils "./utils";
import Types "./types";

actor class Avatar() = {
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;
    type Image = Types.Image;
    type Username = Text;

    let ACTOR_NAME : Text = "Avatar";
    let MAX_BYTES = 2_000_000;

    var avatars : HashMap.HashMap<Username, Image> = HashMap.HashMap(1, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public func is_full() : async Bool {
        // TODO: change to query
        let MAX_SIZE_THRESHOLD_MB : Float = 3500;

        let rtsMemorySize : Nat = Prim.rts_memory_size();
        let memSize : Float = Float.fromInt(rtsMemorySize);
        let memoryInMegabytes =  Float.abs(memSize * 0.000001);

        if (memoryInMegabytes > MAX_SIZE_THRESHOLD_MB) {
            return true;
        } else {
            return false;
        }
    };

    public shared func set(avatar: Image, username: Username) : async Bool {
        if (avatar.content.size() > MAX_BYTES) {
            return false;
        };

        let isValidImg = Utils.is_valid_image(avatar.content);

        if (isValidImg == false) {
            return false;
        };

        avatars.put(username, avatar);

        return true;
    };

    public shared query func http_request(req : HttpRequest) : async HttpResponse {
        let username : Text = Utils.get_username(req.url);
        let NOT_FOUND : [Nat8] = [0];

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
