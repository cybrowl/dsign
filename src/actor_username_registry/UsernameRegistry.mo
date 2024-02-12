import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import CreatorTypes "../actor_creator/types";

import Utils "./utils";

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
		#UserAnonymous;
		#UsernameInvalid;
		#UsernameTaken;

		#NotAuthorizedCaller;

		#UserPrincipalNotFound;
		#UsernameNotFound;

		#ErrorCall : Text;
	};

	type CreatorActor = CreatorTypes.CreatorActor;

	// ------------------------- Variables -------------------------
	let VERSION : Nat = 1; // The Version in Production
	let MAX_USERS : Nat = 100;
	let ACTOR_NAME : Text = "UsernameRegistry";
	var creator_canister_id = "";

	// Username Info
	var username_info : HashMap.HashMap<Username, UsernameInfo> = HashMap.HashMap(
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
				#err(#UserPrincipalNotFound);
			};
		};
	};

	// Get Username Info
	public query ({ caller }) func get_username_info(username : Username) : async Result.Result<UsernameInfo, ErrUsername> {
		switch (username_info.get(username)) {
			case (?info) {
				#ok(info);
			};
			case (_) {
				#err(#UsernameNotFound);
			};
		};
	};

	// ------------------------- Profile Creation -------------------------
	private func username_available(username : Username) : Bool {
		switch (username_info.get(username)) {
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
			return #err(#UserAnonymous);
		};

		if (Utils.is_valid_username(username)) {
			return #err(#UsernameInvalid);
		};

		if (username_available(username)) {
			return #err(#UsernameTaken);
		};

		let creator_actor : CreatorActor = actor (creator_canister_id);

		switch (await creator_actor.create_profile(username)) {
			case (#err err) {
				switch (err) {
					case (#MaxUsersExceeded) {
						// TODO: create a new `creator` canister and asign the user to that `canister_id`
						return #err(#UsernameTaken);
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
				// On successful profile creation, perform necessary storage operations
				// TODO: Implement storage logic for username and username_info
				return #ok(username);
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
