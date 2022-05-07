import Types "./types";

actor class SnapImages() = {
    type ImageID = Types.ImageID;
    type Image = Types.Image;

    let ACTOR_NAME : Text = "SnapImages";
    let MAX_BYTES = 2_000_000;

    var avatars : HashMap.HashMap<ImageID, Image> = HashMap.HashMap(1, Text.equal, Text.hash);

    public query func version() : async Text {
        return "0.0.1";
    };

    public query func add() : async Text {

    };
};