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

actor Profile = {
	type ImageAssetsActor = Types.ImageAssetsActor;
	type ICInterface = Types.ICInterface;
	type Profile = Types.Profile;
	type ProfileErr = Types.ProfileErr;
	type ProfileOk = Types.ProfileOk;
	type Username = Types.Username;
	type UserPrincipal = Types.UserPrincipal;

	let ACTOR_NAME : Text = "Profile";
	let CYCLE_AMOUNT : Nat = 100_000_0000_000;

	private let ic : ICInterface = actor "aaaaa-aa";

	var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var profiles_stable_storage : [(UserPrincipal, Profile)] = [];

	stable var image_assets_canister_id : Text = "";

	public query func version() : async Text {
		return "0.0.1";
	};

	// note: this is only invoked from username.create_username()
	public shared func create_profile(principal : UserPrincipal, username : Username) : async () {

		// TODO: only username should be able to call this
		let profile : Profile = {
			avatar = {
				id = "";
				canister_id = "";
				url = "";
				exists = false;
			};
			created = Time.now();
			username = username;
		};

		profiles.put(principal, profile);
	};

	public shared({ caller }) func update_profile_avatar(img_asset_ids : [Nat]) : async Result.Result<Text, ProfileErr> {
		var profile = {
			avatar = {
				id = "";
				canister_id = "";
				url = "";
				exists = false;
			};
			created = Time.now();
			username = "";
		};

		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound);
			};
			case (?profile_) {
				profile := profile_;
			};
		};

		if (profile.avatar.exists == false) {
			let image_assets_actor = actor (image_assets_canister_id) : ImageAssetsActor;

			switch (await image_assets_actor.save_images(img_asset_ids, "avatar", caller)) {
				case (#err err) {
					return #err(#ErrorCall(debug_show (err)));
				};
				case (#ok images) {
					let image = images[0];

					let profile_modified = {
						avatar = {
							id = image.id;
							canister_id = image.canister_id;
							url = image.url;
							exists = true;
						};
						created = profile.created;
						username = profile.username;
					};

					profiles.put(caller, profile_modified);

					return #ok(profile_modified.avatar.url);
				};
			};
		} else {
			let img_avatar_canister_id = profile.avatar.canister_id;
			let stored_asset_id = profile.avatar.id;

			let image_assets_actor = actor (img_avatar_canister_id) : ImageAssetsActor;

			let asset_id = img_asset_ids[0];
			ignore image_assets_actor.update_image(asset_id, stored_asset_id, "avatar", caller);

			return #ok("updated avatar");
		};
	};

	//TODO: update_profile_banner

	public query ({ caller }) func get_profile() : async Result.Result<ProfileOk, ProfileErr> {
		switch (profiles.get(caller)) {
			case (null) {
				#err(#ProfileNotFound);
			};
			case (?profile) {
				return #ok({ profile });
			};
		};
	};

	//TODO: get_profile_public

	// ------------------------- Canister Management -------------------------
	private func create_image_assets_canister(profile_principal : Principal, is_prod : Bool) : async () {
		let tags = [ACTOR_NAME, "create_image_assets_canister"];

		Cycles.add(CYCLE_AMOUNT);
		let image_assets_actor = await ImageAssets.ImageAssets(profile_principal, is_prod);
		let principal = Principal.fromActor(image_assets_actor);

		image_assets_canister_id := Principal.toText(principal);

		await Logger.log_event(
			tags,
			debug_show (("image_assets_canister_id: ", image_assets_canister_id))
		);
	};

	public shared({ caller }) func install_code(
		canister_id : Principal,
		arg : Blob,
		wasm_module : Blob
	) : async Text {
		let principal = Principal.toText(caller);

		if (Text.equal(principal, "be7if-4i5lo-xnuq5-6ilpw-aedq2-epko6-gdmew-kzcse-7qpey-wztpj-qqe")) {
			await ic.install_code({
				arg = arg;
				wasm_module = wasm_module;
				mode = #upgrade;
				canister_id = canister_id;
			});

			return "success";
		};

		return "not_authorized";
	};

	public shared(msg) func initialize_canisters() : async () {
		let tags = [ACTOR_NAME, "initialize_canisters"];
		let profile_principal = Principal.fromActor(Profile);
		let is_prod = Text.equal(
			Principal.toText(profile_principal),
			"kxkd5-7qaaa-aaaag-aaawa-cai"
		);

		// create image assets canister
		if (image_assets_canister_id.size() < 1) {
			await create_image_assets_canister(profile_principal, is_prod);
		} else {
			await Logger.log_event(
				tags,
				debug_show (("image_assets_canister_id: ", image_assets_canister_id))
			);
		};
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		profiles_stable_storage := Iter.toArray(profiles.entries());
	};

	system func postupgrade() {
		profiles := HashMap.fromIter<UserPrincipal, Profile>(
			profiles_stable_storage.vals(),
			0,
			Principal.equal,
			Principal.hash
		);
		profiles_stable_storage := [];
	};
};
