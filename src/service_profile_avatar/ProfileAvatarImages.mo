import Debug "mo:base/Debug";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Profile "canister:profile";

import Types "./types";
import Utils "./utils";

actor class ProfileAvatarImages() = {
    type AvatarImgErr = Types.AvatarImgErr;
    type AvatarImgOk = Types.AvatarImgOk;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;
    type Image = Types.Image;
    type Username = Types.Username;
    type UserPrincipal =  Types.UserPrincipal;

    let ACTOR_NAME : Text = "ProfileAvatarImages";
    let MAX_BYTES = 2_000_000;

    var avatar_images : HashMap.HashMap<Username, Image> = HashMap.HashMap(0, Text.equal, Text.hash);

    public shared ({caller}) func whoami() : async Principal {
        return caller;
    };

    public func get_canister_id() : async Principal {
        return await whoami();
    };

    public query func version() : async Text {
        return "0.0.1";
    };

    public query func is_full() : async Bool {
        let MAX_SIZE_THRESHOLD_MB : Float = 3500;

        let rts_memory_size : Nat = Prim.rts_memory_size();
        let mem_size : Float = Float.fromInt(rts_memory_size);
        let memory_in_megabytes =  Float.abs(mem_size * 0.000001);

        if (memory_in_megabytes > MAX_SIZE_THRESHOLD_MB) {
            return true;
        } else {
            return false;
        }
    };

    public shared ({caller}) func save_image(avatar: Image, username: Username) : async Result.Result<AvatarImgOk, AvatarImgErr> {
        if (avatar.content.size() > MAX_BYTES) {
            return #err(#AvatarImgTooBig);
        };

        let is_valid_img = Utils.is_valid_image(avatar.content);

        if (is_valid_img == false) {
            return #err(#ImgNotValid);
        };

        avatar_images.put(username, avatar);

        let canister_id = await get_canister_id();
        let avatar_images_canister_id = Principal.toText(canister_id);

        switch(await Profile.update_avatar_url(avatar_images_canister_id, username, caller)) {
            case(#err update_avatar_url_err){
                return #err(#ProfileFailedToUpdateAvatarUrl);
            };
            case(#ok avatar_url){
                #ok({avatar_url});
            };
        }
    };

    public shared query func http_request(req : HttpRequest) : async HttpResponse {
        let username : Text = Utils.get_username(req.url);
        let NOT_FOUND : [Nat8] = [0];

        switch (avatar_images.get(username)) {
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