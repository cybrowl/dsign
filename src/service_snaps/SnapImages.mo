import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import H "mo:base/HashMap";
import Rand "mo:base/Random";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import Types "./types";

actor class SnapImages() = {
    type ImageID = Types.ImageID;
    type Image = Types.Image;

    let ACTOR_NAME : Text = "SnapImages";
    let MAX_BYTES = 2_000_000;

    
    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);

    var avatars : H.HashMap<ImageID, Image> = H.HashMap(1, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public shared (msg) func add() : async Text {
        let id = se.new();
        let imageID : ImageID = ULID.toText(id);
        
        Debug.print(imageID);

        return "hello";
    };
};