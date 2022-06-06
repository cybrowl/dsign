import Debug "mo:base/Debug";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Prim "mo:⛔";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";

actor class ProfileAvatarImages() = {
    type Username = Types.Username;
    type UserPrincipal =  Types.UserPrincipal;

    let ACTOR_NAME : Text = "ProfileAvatarImages";
    let MAX_BYTES = 2_000_000;

    var avatar_images : HashMap.HashMap<Username, Image> = HashMap.HashMap(0, Text.equal, Text.hash);

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
};