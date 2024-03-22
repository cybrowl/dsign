import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CreatorTypes "../actor_creator/types";
import ExploreTypes "../actor_explore/types";
import ICTypes "../c_types/ic";

import Creator "../actor_creator/Creator";
import Explore "canister:explore";
import Logger "canister:logger";
import Mo "canister:mo";

import Health "../libs/health";
import Registry "../libs/registry";
import Utils "./utils";

import Types "./types";

import { IS_PROD } "../env/env";

actor UsernameRegistry = {
	// NOTE:
	// Principal, CanisterId, Username
	// Manages Usernames & the CanisterId Associated with that Username
	// Source of Truth to Principal ownership of Username

	type CanisterInfo = Types.CanisterInfo;
	type ErrUsername = Types.ErrUsername;
	type Username = Types.Username;
	type UsernameInfo = Types.UsernameInfo;

	type CreatorActor = CreatorTypes.CreatorActor;
	type ExploreActor = ExploreTypes.ExploreActor;
	type ICManagementActor = ICTypes.Self;

	// ------------------------- Variables -------------------------
	let ACTOR_NAME : Text = "UsernameRegistry";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;
	let VERSION : Nat = 7; // The Version in Production

	stable var creator_canister_id = "";

	// ------------------------- Storage Data -------------------------
	// Username Info
	var usernames_info : HashMap.HashMap<Username, UsernameInfo> = HashMap.HashMap(
		0,
		Text.equal,
		Text.hash
	);
	stable var usernames_info_stable_storage : [(Username, UsernameInfo)] = [];

	// Username
	var usernames : HashMap.HashMap<Principal, Username> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var usernames_stable_storage : [(Principal, Username)] = [];

	// Canister Registry for Creator
	var canister_registry_creator : HashMap.HashMap<Principal, CanisterInfo> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var canister_registry_creator_stable_storage : [(Principal, CanisterInfo)] = [];

	// ------------------------- Actor -------------------------
	private let ic_management_actor : ICManagementActor = actor "aaaaa-aa";

	// ------------------------- Username -------------------------
	// Get Username
	public query ({ caller }) func get_username() : async Result.Result<Username, ErrUsername> {
		switch (usernames.get(caller)) {
			case (?username) {
				#ok(username);
			};
			case (_) {
				#err(#UserPrincipalNotFound(true));
			};
		};
	};

	// Get Username
	public query func get_username_by_principal(creator : Principal) : async Result.Result<Username, ErrUsername> {
		switch (usernames.get(creator)) {
			case (?username) {
				#ok(username);
			};
			case (_) {
				#err(#UserPrincipalNotFound(true));
			};
		};
	};

	// Get Info
	public query ({ caller }) func get_info() : async Result.Result<UsernameInfo, ErrUsername> {
		switch (usernames.get(caller)) {
			case (?username) {
				switch (usernames_info.get(username)) {
					case (?info) {
						#ok(info);
					};
					case (_) {
						#err(#UsernameNotFound(true));
					};
				};
			};
			case (_) {
				#err(#UserPrincipalNotFound(true));
			};
		};
	};

	// Get Info by Username
	public query func get_info_by_username(username : Username) : async Result.Result<UsernameInfo, ErrUsername> {
		switch (usernames_info.get(username)) {
			case (?info) {
				#ok(info);
			};
			case (_) {
				#err(#UsernameNotFound(true));
			};
		};
	};

	// ------------------------- Profile Creation -------------------------
	private func username_available(username : Username) : Bool {
		switch (usernames_info.get(username)) {
			case (?owner) {
				return false;
			};
			case (_) {
				return true;
			};
		};
	};

	// Create Profile
	public shared ({ caller }) func create_profile(username : Username) : async Result.Result<Username, ErrUsername> {

		// let tags = [
		//     ("name", ACTOR_NAME),
		//     ("method", "create_profile")
		// ];

		if (Principal.isAnonymous(caller)) {
			return #err(#CallerAnonymous(true));
		};

		if (Utils.username_valid(username) == false) {
			return #err(#UsernameInvalid(true));
		};

		if (username_available(username) == false) {
			return #err(#UsernameTaken(true));
		};

		let creator_actor : CreatorActor = actor (creator_canister_id);

		switch (await creator_actor.create_profile(username, caller)) {
			case (#err err) {
				switch (err) {
					case (#MaxUsersExceeded) {
						await create_creator_canister(IS_PROD);

						let creator_actor : CreatorActor = actor (creator_canister_id);

						switch (await creator_actor.create_profile(username, caller)) {
							case (#err err) {
								switch (err) {
									case (#MaxUsersExceeded) {
										return #err(#ErrorCall(debug_show (err)));
									};
									case _ {
										return #err(#ErrorCall(debug_show (err)));
									};
								};
							};
							case (#ok _) {
								let username_info : UsernameInfo = {
									canister_id = creator_canister_id;
									username = username;
								};

								usernames.put(caller, username);
								usernames_info.put(username, username_info);

								return #ok(username);
							};
						};
					};
					case (#NotAuthorizedCaller) {
						return #err(#ErrorCall(debug_show (err)));
					};
					case _ {
						return #err(#ErrorCall(debug_show (err)));
					};
				};
			};
			case (#ok _) {
				let username_info : UsernameInfo = {
					canister_id = creator_canister_id;
					username = username;
				};

				usernames.put(caller, username);
				usernames_info.put(username, username_info);

				return #ok(username);
			};
		};
	};

	// Delete Profile
	public shared ({ caller }) func delete_profile() : async Result.Result<Bool, ErrUsername> {
		switch (usernames.get(caller)) {
			case (?username) {

				usernames.delete(caller);

				usernames_info.delete(username);

				// TODO: delete from CreatorActor

				return #ok(true);
			};
			case (_) {
				return #err(#UserPrincipalNotFound(true));
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	// Version
	public query func version() : async Nat {
		return VERSION;
	};

	// Get Registry
	public query func get_registry() : async [CanisterInfo] {
		return Iter.toArray(canister_registry_creator.vals());
	};

	// Create Creator Canister
	private func create_creator_canister<system>(is_prod : Bool) : async () {
		let username_registry_principal = Principal.fromActor(UsernameRegistry);

		Cycles.add<system>(CYCLE_AMOUNT);
		let creator_actor = await Creator.Creator(username_registry_principal);
		let principal = Principal.fromActor(creator_actor);

		ignore creator_actor.init();

		creator_canister_id := Principal.toText(principal);

		let canister_info : CanisterInfo = {
			created = Time.now();
			id = Principal.toText(principal);
			name = "Creator";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		canister_registry_creator.put(principal, canister_info);

		ignore Explore.save_canister_info_from_creator(canister_info);
		ignore Mo.save_canister_info_from_creator(canister_info);
	};

	// Init
	public shared func init() : async Text {
		let tags = [("actor_name", ACTOR_NAME), ("method", "init")];

		let creator_cids = Iter.toArray(canister_registry_creator.vals());

		let registry_creator : [Text] = Registry.get_canister_ids(creator_cids);
		let username_registry_id : Text = Principal.toText(Principal.fromActor(UsernameRegistry));

		ignore Logger.add_canister_id_to_registry(registry_creator);
		ignore Logger.add_canister_id_to_registry([username_registry_id]);

		if (creator_canister_id.size() > 1) {
			ignore Logger.log_event(tags, "exists creator_canister_id: " # creator_canister_id);

			return creator_canister_id;
		} else {
			await create_creator_canister(IS_PROD);

			ignore Logger.log_event(tags, "created creator_canister_id: " # creator_canister_id);

			return creator_canister_id;
		};
	};

	// Upgrade
	public shared ({ caller }) func install_code(
		canister_id : Principal,
		arg : Blob,
		wasm_module : Blob
	) : async Text {
		let caller_principal = Principal.toText(caller);
		let admin_principal = "pimnv-hjnlu-go5zn-6wkn3-xb7l5-al2yp-udeku-genyx-aqgd2-qy4xn-nae";

		if (Text.equal(caller_principal, admin_principal)) {
			await ic_management_actor.install_code({
				arg = arg;
				wasm_module = wasm_module;
				mode = #upgrade;
				canister_id = canister_id;
			});

			return "upgrated";
		} else {
			return "failed to upgrade";
		};
	};

	// Health
	public shared func health() : async () {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("version", Int.toText(VERSION)),
			("usernames_info_size", Int.toText(usernames_info.size())),
			("usernames_size", Int.toText(usernames.size())),
			("cycles_balance", Int.toText(Health.get_cycles_balance())),
			("memory_in_mb", Int.toText(Health.get_memory_in_mb())),
			("heap_in_mb", Int.toText(Health.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);

		return ();
	};

	// Low Cycles
	public query func cycles_low() : async Bool {
		return Health.get_cycles_low();
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		usernames_info_stable_storage := Iter.toArray(usernames_info.entries());
		usernames_stable_storage := Iter.toArray(usernames.entries());
		canister_registry_creator_stable_storage := Iter.toArray(canister_registry_creator.entries());
	};

	system func postupgrade() {
		usernames_info := HashMap.fromIter<Username, UsernameInfo>(
			usernames_info_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		usernames_info_stable_storage := [];

		usernames := HashMap.fromIter<Principal, Username>(
			usernames_stable_storage.vals(),
			0,
			Principal.equal,
			Principal.hash
		);
		usernames_stable_storage := [];

		canister_registry_creator := HashMap.fromIter<Principal, CanisterInfo>(
			canister_registry_creator_stable_storage.vals(),
			0,
			Principal.equal,
			Principal.hash
		);
		canister_registry_creator_stable_storage := [];
	};
};
