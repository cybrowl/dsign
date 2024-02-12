import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Utils "./utils";

actor UsernameRegistry = {
	let VERSION : Nat = 1; // The Version in Production
	let MAX_USERS : Nat = 100;
	let ACTOR_NAME : Text = "UsernameRegistry";

	//NOTE:
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

		#UserNotAuthorized;
		#UsernameNotFound;
		#UserNotFound;
	};

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

	// ------------------------- Profile -------------------------

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

		return #ok("");

		//TODO: call `creator` to create profile
		//TODO: check if there is enough space in the `creator` canister
		// if not then create a new `creator` canister and assign the user to it
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
