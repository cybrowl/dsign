import { Buffer; toArray } "mo:base/Buffer";
import Time "mo:base/Time";

import CanisterLedgerTypes "../types/canister_child_ledger.types";

actor CanisterChildLedger = {
	type CanisterChild = CanisterLedgerTypes.CanisterChild;

	var canisters = Buffer<CanisterChild>(0);

	public query func ping() : async Text {
		return "meow";
	};

	public shared func save_canister(canister_child : CanisterChild) : async Text {
		//TODO: only allow main canisters to call this

		canisters.add(canister_child);

		return "ok";
	};

	public query func get_canisters() : async [CanisterChild] {
		return toArray(canisters);
	};
};
