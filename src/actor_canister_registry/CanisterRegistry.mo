actor CanisterRegistry = {

	// The Version in Production
	let VERSION : Nat = 1;

	//NOTE:
	// Principal, CanisterId, Username
	// Manages Creator Canisters

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};