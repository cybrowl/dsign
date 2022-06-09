import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Logger "canister:logger";
import ProfileAvatarImages "ProfileAvatarImages";

import Utils "./utils";
import Types "./types";

actor class ProfileAvatarMain() = {
    type AvatarImgErr = Types.AvatarImgErr;
    type AvatarImgOk = Types.AvatarImgOk;
    type Image = Types.Image;
    type ProfileAvatarImagesActor = Types.ProfileAvatarImagesActor;
    type ProfileAvatarImagesCanisterId = Types.ProfileAvatarImagesCanisterId;
    type Username = Types.Username;
    type UserPrincipal =  Types.UserPrincipal;

    let ACTOR_NAME : Text = "ProfileAvatarMain";
    let CYCLE_AMOUNT : Nat = 1_000_000_000;
    let MAX_BYTES = 2_000_000;

    var canister_history : H.HashMap<ProfileAvatarImagesCanisterId, ProfileAvatarImagesCanisterId> = H.HashMap(0, Text.equal, Text.hash);
    // holds data until filled
    // once filled, a new canister is created and assigned
    var profile_avatar_images_canister_id : Text = "";

    public query func version() : async Text {
        return "0.0.1";
    };

    public shared ({caller}) func save_image(avatar: Image) : async Result.Result<AvatarImgOk, AvatarImgErr> {
        if (avatar.content.size() > MAX_BYTES) {
            return #err(#AvatarImgTooBig);
        };

        let is_valid_img = Utils.is_valid_image(avatar.content);

        if (is_valid_img == false) {
            return #err(#ImgNotValid);
        };

        let profile_avatar_images_actor = actor (profile_avatar_images_canister_id) : ProfileAvatarImagesActor;

        switch(await profile_avatar_images_actor.save_image(avatar, caller)) {
            case(#ok avatar_url){
                #ok(avatar_url);
            };
            case(_){
                return #err(#FailedSaveAvatarImg);
            };
        };
    };

    private func create_avatar_images_canister() : async () {
        let tags = [ACTOR_NAME, "create_avatar_images_canister"];

        // create canister
        Cycles.add(CYCLE_AMOUNT);
        let profile_avatar_images_actor = await ProfileAvatarImages.ProfileAvatarImages();
        let principal = Principal.fromActor(profile_avatar_images_actor);
        let profile_avatar_images_canister_id_ = Principal.toText(principal);

        profile_avatar_images_canister_id := profile_avatar_images_canister_id_;

        canister_history.put(profile_avatar_images_canister_id, profile_avatar_images_canister_id);

        await Logger.log_event(tags, debug_show(("profile_avatar_images_canister_id: ", profile_avatar_images_canister_id)));
    };

    public shared (msg) func initialize_canisters(profileAvatarImagesCanisterId: ?Text) : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];

        // create canister
        if (profile_avatar_images_canister_id.size() < 1) {
            switch (profileAvatarImagesCanisterId) {
                case null  {
                    await create_avatar_images_canister();
                };
                case (?canister_id) {
                    await Logger.log_event(tags, debug_show(("avatar images initialized", canister_id)));
                    profile_avatar_images_canister_id := canister_id;
                };
            };
        } else {
            await Logger.log_event(tags, debug_show(("avatar images exists", profile_avatar_images_canister_id)));
        };
    };
};
