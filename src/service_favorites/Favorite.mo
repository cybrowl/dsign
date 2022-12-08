import { Buffer; toArray } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";

actor class Favorite(favorite_main : Principal) = this {
	type ErrDeleteFavorite = Types.ErrDeleteFavorite;
	type ErrGetFavorite = Types.ErrGetFavorite;
	type ErrSaveFavorite = Types.ErrSaveFavorite;
	type SnapCanisterId = Types.SnapCanisterId;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;

	let ACTOR_NAME : Text = "Favorite";
	let VERSION : Nat = 1;

	var snaps : HashMap.HashMap<SnapID, SnapPublic> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var snaps_stable_storage : [(SnapID, SnapPublic)] = [];

	public shared ({ caller }) func save_snap(snap : SnapPublic) : async Result.Result<SnapPublic, ErrSaveFavorite> {
		if (favorite_main != caller) {
			return #err(#NotAuthorized(true));
		};

		snaps.delete(snap.id);

		snaps.put(snap.id, snap);

		return #ok(snap);
	};

	public shared ({ caller }) func delete_snap(snap_id : SnapID) : async Result.Result<SnapPublic, ErrDeleteFavorite> {
		if (favorite_main != caller) {
			return #err(#NotAuthorized(true));
		};

		switch (snaps.get(snap_id)) {
			case null {
				return #err(#SnapNotFound(true));
			};
			case (?snap) {
				snaps.delete(snap_id);

				return #ok(snap);
			};
		};
	};

	public query ({ caller }) func get_all_snaps(snap_ids : [SnapID]) : async Result.Result<[SnapPublic], ErrGetFavorite> {
		if (favorite_main != caller) {
			return #err(#NotAuthorized(true));
		};

		var snaps_list = Buffer<SnapPublic>(0);

		for (snap_id in snap_ids.vals()) {
			switch (snaps.get(snap_id)) {
				case null {};
				case (?snap) {

					snaps_list.add(snap);
				};
			};
		};

		return #ok(toArray(snaps_list));
	};

	public query func length() : async Nat {
		return snaps.size();
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		snaps_stable_storage := Iter.toArray(snaps.entries());
	};

	system func postupgrade() {
		snaps := HashMap.fromIter<SnapID, SnapPublic>(
			snaps_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		snaps_stable_storage := [];
	};
};
