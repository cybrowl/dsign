actor Explore {
	let VERSION = 1;

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
