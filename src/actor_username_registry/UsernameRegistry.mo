actor UsernameRegistry = {

	// The Version in Production
	let VERSION : Nat = 1;

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
