import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import CreatorTypes "../actor_creator/types";

import Creator "../actor_creator/Creator";
import Logger "canister:logger";

import Utils "./utils";

import { IS_PROD; ENV } "../env/env";

actor UsernameRegistry = {
	// NOTE:
	// Principal, CanisterId, Username
	// Manages Usernames & the CanisterId Associated with that Username
	// Source of Truth to Principal ownership of Username

	type Username = Text;
	type UsernameInfo = {
		canister_id : Text;
	};
	type ErrUsername = {
		#CallerAnonymous : Bool;
		#UsernameInvalid : Bool;
		#UsernameTaken : Bool;
		#UserPrincipalNotFound : Bool;
		#UsernameNotFound : Bool;
		#ErrorCall : Text;
	};

	type CreatorActor = CreatorTypes.CreatorActor;

	// ------------------------- Variables -------------------------
	let VERSION : Nat = 1; // The Version in Production
	let MAX_USERS : Nat = 100;
	let ACTOR_NAME : Text = "UsernameRegistry";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;

	var creator_canister_id = "";

	// Username Info
	var usernames_info : HashMap.HashMap<Username, UsernameInfo> = HashMap.HashMap(
		0,
		Text.equal,
		Text.hash
	);

	// Username
	var usernames : HashMap.HashMap<Principal, Username> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);

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

	// Get Username Info
	public query ({ caller }) func get_username_info(username : Username) : async Result.Result<UsernameInfo, ErrUsername> {
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

		let tags = [
			("name", ACTOR_NAME),
			("method", "create_profile")
		];

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

		switch (await creator_actor.create_profile(username)) {
			case (#err err) {
				switch (err) {
					case (#MaxUsersExceeded) {
						// TODO: create a new `creator` canister and asign the user to that `canister_id`
						return #err(#ErrorCall(debug_show (err)));
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

				return #ok(true);
			};
			case (_) {
				return #err(#UserPrincipalNotFound(true));
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	private func create_creator_canister(is_prod : Bool) : async () {
		let username_registry_principal = Principal.fromActor(UsernameRegistry);

		Cycles.add(CYCLE_AMOUNT);
		let creator_actor = await Creator.Creator(username_registry_principal);
		let principal = Principal.fromActor(creator_actor);

		creator_canister_id := Principal.toText(principal);

		// let canister_child : CanisterInfo = {
		//     created = Time.now();
		//     id = favorite_canister_id;
		//     name = "favorite";
		//     parent_name = ACTOR_NAME;
		//     isProd = is_prod;
		// };

		// ignore CanisterIdsLedger.save_canister(canister_child);
	};

	public shared (msg) func initialize_canisters() : async Text {
		let tags = [("actor_name", ACTOR_NAME), ("method", "initialize_canisters")];

		if (creator_canister_id.size() > 1) {
			ignore Logger.log_event(tags, "exists creator_canister_id: " # creator_canister_id);

			return creator_canister_id;
		} else {
			await create_creator_canister(IS_PROD);

			ignore Logger.log_event(tags, "created creator_canister_id: " # creator_canister_id);

			return creator_canister_id;
		};
	};
};
