import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CanisterChildLedger "canister:canister_child_ledger";
import ImageAssets "../service_assets_img/ImageAssets";
import Logger "canister:logger";

import Types "./types";
import CanisterLedgerTypes "../types/canister_child_ledger.types";

import Utils "./utils";

actor Profile = {
	type ErrProfile = Types.ErrProfile;
	type ErrUsername = Types.ErrUsername;
	type ICInterface = Types.ICInterface;
	type ImageAssetsActor = Types.ImageAssetsActor;
	type Profile = Types.Profile;
	type Username = Types.Username;
	type UserPrincipal = Types.UserPrincipal;

	type CanisterChild = CanisterLedgerTypes.CanisterChild;

	let ACTOR_NAME : Text = "Profile";
	let CYCLE_AMOUNT : Nat = 100_000_0000_000;
	let VERSION : Nat = 2;

	private let ic : ICInterface = actor "aaaaa-aa";

	// ------------------------- Variables -------------------------
	// usernames
	var username_owners : HashMap.HashMap<Username, UserPrincipal> = HashMap.HashMap(
		0,
		Text.equal,
		Text.hash
	);
	stable var username_owners_stable_storage : [(Username, UserPrincipal)] = [];

	var usernames : HashMap.HashMap<UserPrincipal, Username> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var usernames_stable_storage : [(UserPrincipal, Username)] = [];

	// profiles
	var profiles : HashMap.HashMap<UserPrincipal, Profile> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var profiles_stable_storage : [(UserPrincipal, Profile)] = [];

	stable var image_assets_canister_id : Text = "";

	// ------------------------- Username Methods -------------------------
	private func check_username_is_available(username : Username) : Bool {
		switch (username_owners.get(username)) {
			case (?owner) {
				return false;
			};
			case (_) {
				return true;
			};
		};
	};

	private func check_user_has_a_username(caller : UserPrincipal) : Bool {
		switch (usernames.get(caller)) {
			case (?username) {
				return true;
			};
			case (_) {
				return false;
			};
		};
	};

	private func get_current_username(caller : UserPrincipal) : Username {
		switch (usernames.get(caller)) {
			case (?current_username) {
				return current_username;
			};
			case (_) {
				return "";
			};
		};
	};

	public shared ({ caller }) func create_username(username : Username) : async Result.Result<Username, ErrUsername> {
		let tags = [ACTOR_NAME, "create_username"];
		let is_anonymous = Principal.isAnonymous(caller);

		let valid_username : Bool = Utils.is_valid_username(username);
		let username_available : Bool = check_username_is_available(username);
		let user_has_username : Bool = check_user_has_a_username(caller);

		if (is_anonymous == true) {
			return #err(#UserAnonymous);
		};

		if (valid_username == false) {
			return #err(#UsernameInvalid);
		};

		if (username_available == false) {
			return #err(#UsernameTaken);
		};

		if (user_has_username == true) {
			return #err(#UserHasUsername);
		} else {
			usernames.put(caller, username);
			username_owners.put(username, caller);

			await Logger.log_event(tags, "created");

			// create profile
			let profile : Profile = {
				avatar = {
					id = "";
					canister_id = "";
					url = "";
					exists = false;
				};
				banner = {
					id = "";
					canister_id = "";
					url = "";
					exists = false;
				};
				created = Time.now();
				username = username;
			};

			profiles.put(caller, profile);

			return #ok(username);
		};
	};

	// public shared ({ caller }) func update_username(username : Username) : async Result.Result<UsernameOk, UsernameErr> {
	// 	let tags = [ACTOR_NAME, "update_username"];
	// 	let is_anonymous = Principal.isAnonymous(caller);

	// 	let valid_username : Bool = Utils.is_valid_username(username);
	// 	let username_available : Bool = check_username_is_available(username);
	// 	let user_has_username : Bool = check_user_has_a_username(caller);

	// 	if (is_anonymous == true) {
	// 		return #err(#UserAnonymous);
	// 	};

	// 	if (valid_username == false) {
	// 		return #err(#UsernameInvalid);
	// 	};

	// 	if (user_has_username == false) {
	// 		return #err(#UsernameNotFound);
	// 	};

	// 	if (username_available == false) {
	// 		return #err(#UsernameTaken);
	// 	} else {
	// 		let current_username : Username = get_current_username(caller);
	// 		username_owners.delete(current_username);
	// 		username_owners.put(username, caller);
	// 		usernames.put(caller, username);

	// 		await Logger.log_event(tags, "updated");

	// 		//TODO: update username in snaps, profile, avatar_url

	// 		return #ok(username);
	// 	};
	// };

	public query func get_number_of_users() : async Nat {
		return usernames.size();
	};

	public query ({ caller }) func get_username() : async Result.Result<Username, ErrUsername> {
		switch (usernames.get(caller)) {
			case (?username) {
				#ok(username);
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	public query func get_username_public(principal : UserPrincipal) : async Result.Result<Username, ErrUsername> {
		switch (usernames.get(principal)) {
			case (?username) {
				#ok(username);
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	public query func get_user_principal_public(username : Username) : async Result.Result<UserPrincipal, ErrUsername> {
		//TODO: lock for authorized canisters only

		switch (username_owners.get(username)) {
			case (?principal) {
				#ok(principal);
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	// ------------------------- Profile Methods -------------------------
	public shared ({ caller }) func update_profile_avatar(img_asset_ids : [Nat]) : async Result.Result<Text, ErrProfile> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound);
			};
			case (?profile) {
				if (profile.avatar.exists == false) {
					let image_assets_actor = actor (image_assets_canister_id) : ImageAssetsActor;

					switch (await image_assets_actor.save_images(img_asset_ids, "avatar", caller)) {
						case (#err err) {
							return #err(#ErrorCall(debug_show (err)));
						};
						case (#ok images) {
							let image = images[0];

							let profile_modified = {
								profile with avatar = {
									id = image.id;
									canister_id = image.canister_id;
									url = image.url;
									exists = true;
								};
							};

							profiles.put(caller, profile_modified);

							return #ok(profile_modified.avatar.url);
						};
					};
				} else {
					let image_assets_actor = actor (profile.avatar.canister_id) : ImageAssetsActor;

					ignore image_assets_actor.update_image(img_asset_ids[0], profile.avatar.id, "avatar", caller);

					return #ok("updated avatar");
				};
			};
		};

	};

	public shared ({ caller }) func update_profile_banner(img_asset_ids : [Nat]) : async Result.Result<Text, ErrProfile> {
		switch (profiles.get(caller)) {
			case (null) {
				return #err(#ProfileNotFound);
			};
			case (?profile) {
				if (profile.banner.exists == false) {
					let image_assets_actor = actor (image_assets_canister_id) : ImageAssetsActor;

					switch (await image_assets_actor.save_images(img_asset_ids, "banner", caller)) {
						case (#err err) {
							return #err(#ErrorCall(debug_show (err)));
						};
						case (#ok images) {
							let image = images[0];

							let profile_modified = {
								profile with banner = {
									id = image.id;
									canister_id = image.canister_id;
									url = image.url;
									exists = true;
								};
							};

							profiles.put(caller, profile_modified);

							return #ok(profile_modified.banner.url);
						};
					};
				} else {
					let image_assets_actor = actor (profile.banner.canister_id) : ImageAssetsActor;

					ignore image_assets_actor.update_image(img_asset_ids[0], profile.banner.id, "banner", caller);

					return #ok("updated banner");
				};
			};
		};

	};
	//TODO: update_profile

	public query ({ caller }) func get_profile() : async Result.Result<Profile, ErrProfile> {
		switch (profiles.get(caller)) {
			case (null) {
				#err(#ProfileNotFound);
			};
			case (?profile) {
				return #ok(profile);
			};
		};
	};

	public query ({ caller }) func get_profile_public(username : Username) : async Result.Result<Profile, ErrProfile> {
		switch (username_owners.get(username)) {
			case (?principal) {
				switch (profiles.get(principal)) {
					case (null) {
						#err(#ProfileNotFound);
					};
					case (?profile) {
						return #ok(profile);
					};
				};
			};
			case (_) {
				#err(#PrincipalNotFoundForUsername);
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	private func create_image_assets_canister(profile_principal : Principal, is_prod : Bool) : async () {
		let tags = [ACTOR_NAME, "create_image_assets_canister"];

		Cycles.add(CYCLE_AMOUNT);
		let image_assets_actor = await ImageAssets.ImageAssets(profile_principal, is_prod);
		let principal = Principal.fromActor(image_assets_actor);

		image_assets_canister_id := Principal.toText(principal);

		let canister_child : CanisterChild = {
			created = Time.now();
			id = image_assets_canister_id;
			name = "image_assets";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterChildLedger.save_canister(canister_child);

		await Logger.log_event(
			tags,
			debug_show (("image_assets_canister_id: ", image_assets_canister_id))
		);
	};

	public shared ({ caller }) func install_code(
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

	public shared (msg) func initialize_canisters() : async () {
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
		username_owners_stable_storage := Iter.toArray(username_owners.entries());
		usernames_stable_storage := Iter.toArray(usernames.entries());

		profiles_stable_storage := Iter.toArray(profiles.entries());
	};

	system func postupgrade() {
		// owners
		username_owners := HashMap.fromIter<Username, UserPrincipal>(
			username_owners_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		username_owners_stable_storage := [];

		// usernames
		usernames := HashMap.fromIter<UserPrincipal, Username>(
			usernames_stable_storage.vals(),
			0,
			Principal.equal,
			Principal.hash
		);
		usernames_stable_storage := [];

		profiles := HashMap.fromIter<UserPrincipal, Profile>(
			profiles_stable_storage.vals(),
			0,
			Principal.equal,
			Principal.hash
		);
		profiles_stable_storage := [];
	};
};
