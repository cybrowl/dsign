import { Buffer; toArray } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CanisterLedgerTypes "../types/canister_child_ledger.types";

actor CanisterChildLedger = {
	type CanisterChild = CanisterLedgerTypes.CanisterChild;

	var canisters = List.nil<CanisterChild>();
	stable var canisters_stable_storage : [(CanisterChild)] = [];

	var authorized : HashMap.HashMap<Text, Text> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var authorized_stable_storage : [(Text, Text)] = [];

	stable var is_prod : Bool = false;

	public query func ping() : async Text {
		return "meow";
	};

	public shared ({ caller }) func save_canister(canister_child : CanisterChild) : async Text {
		if (is_prod == false) {
			canisters := List.push<CanisterChild>(canister_child, canisters);

			return "Added for Dev";
		} else {
			switch (authorized.get(Principal.toText(caller))) {
				case (null) {
					return "Not Authorized";
				};
				case (?principal) {
					canisters := List.push<CanisterChild>(canister_child, canisters);

					return "Added for Prod";
				};
			};
		};
	};

	public query func get_canisters() : async [CanisterChild] {
		return List.toArray<CanisterChild>(canisters);
	};

	public shared func initialize_authorized_principals() : async Text {
		let canister_child_ledger = Principal.fromActor(CanisterChildLedger);
		let is_production = Text.equal(
			Principal.toText(canister_child_ledger),
			"7t2d4-jiaaa-aaaag-aa36q-cai"
		);

		is_prod := is_production;

		let author : Text = "ru737-xk264-4nswf-o6lzb-3juxx-ixp63-objgb-l4io2-yievs-5ezxe-kqe";
		let favorite_main : Text = "a7b5k-xiaaa-aaaag-aa6ja-cai";
		let profile : Text = "kxkd5-7qaaa-aaaag-aaawa-cai";
		let project_main : Text = "nhlnj-vyaaa-aaaag-aay5q-cai";
		let snap_main : Text = "lyswl-7iaaa-aaaag-aatya-cai";

		if (authorized.size() < 5) {
			authorized.put(author, author);
			authorized.put(favorite_main, favorite_main);
			authorized.put(profile, profile);
			authorized.put(project_main, project_main);
			authorized.put(snap_main, snap_main);

			return "added";
		} else {
			return "exists";
		}

	};

	// ------------------------- SYSTEM METHODS -------------------------
	system func preupgrade() {
		authorized_stable_storage := Iter.toArray(authorized.entries());

		canisters_stable_storage := List.toArray<CanisterChild>(canisters);
	};

	system func postupgrade() {
		authorized := HashMap.fromIter<Text, Text>(
			authorized_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		canisters := List.fromArray<CanisterChild>(canisters_stable_storage);

		authorized_stable_storage := [];
		canisters_stable_storage := [];
	};
};
