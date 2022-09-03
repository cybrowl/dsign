import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import ImageAssets "../service_assets_img/ImageAssets";
import Logger "canister:logger";

import Types "./types";
import Utils "./utils";

actor Profile = {
    type AvatarImgUrl = Types.AvatarImgUrl;
    type Profile = Types.Profile;
    type ProfileError = Types.ProfileError;
    type ProfileOk = Types.ProfileOk;
    type Username = Types.Username;
    type UserPrincipal =  Types.UserPrincipal;

    let ACTOR_NAME : Text = "Profile";
    let CYCLE_AMOUNT : Nat = 100_000_0000_000;

    var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(0, Principal.equal, Principal.hash);
    stable var profiles_stable_storage : [(UserPrincipal, Profile)] = [];

    stable var image_assets_canister_id : Text = "";

    public query func version() : async Text {
        return "0.0.1";
    };

    public query ({caller}) func get_profile() : async Result.Result<ProfileOk, ProfileError> {
        switch (profiles.get(caller)) {
            case (null) {
                #err(#ProfileNotFound)
            };
            case (?profile) {
                return #ok({profile});
            };
        };
    };

    // note: this is only invoked from username.create_username()
    public shared func create_profile(principal: UserPrincipal, username: Username) : async () {
        let profile : Profile = {
            avatar_url = "";
            created = Time.now();
            username = username;
        };

        profiles.put(principal, profile);
    };

    public shared func update_profile_avatar() : async () {

    };

    // ------------------------- Canister Management -------------------------
    private func create_image_assets_canister(profile_principal : Principal) : async () {
        let tags = [ACTOR_NAME, "create_image_assets_canister"];

        Cycles.add(CYCLE_AMOUNT);
        let image_assets_actor = await ImageAssets.ImageAssets(profile_principal);
        let principal = Principal.fromActor(image_assets_actor);

        image_assets_canister_id := Principal.toText(principal);

        await Logger.log_event(tags, debug_show(("image_assets_canister_id: ", image_assets_canister_id)));
    };

    public shared (msg) func initialize_canisters() : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];
        let profile_principal = Principal.fromActor(Profile);

        // create image assets canister
        if (image_assets_canister_id.size() < 1) {
            await create_image_assets_canister(profile_principal);
        } else {
            await Logger.log_event(tags, debug_show(("image_assets_canister_id: ", image_assets_canister_id)));
        };
    };
    // ------------------------- System Methods -------------------------
    system func preupgrade() {
        profiles_stable_storage := Iter.toArray(profiles.entries());
    };

    system func postupgrade() {
        profiles := HashMap.fromIter<UserPrincipal, Profile>(profiles_stable_storage.vals(), 0, Principal.equal, Principal.hash);
        profiles_stable_storage := [];
    };
};
