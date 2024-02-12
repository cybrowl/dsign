import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

actor UsernameRegistry = {

	// The Version in Production
	let VERSION : Nat = 1;

	//NOTE:
	// Principal, CanisterId, Username
	// Manages Usernames & the CanisterId Associated with that Username
	// Source of Truth to Principal ownership of Username

	type Username = Text;
	type UsernameInfo = {
		canister_id : Text;
	};

	// Username Info
	var username_info : HashMap.HashMap<Username, UsernameInfo> = HashMap.HashMap(
		0,
		Text.equal,
		Text.hash
	);

	// Username
	var username : HashMap.HashMap<Principal, Username> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
