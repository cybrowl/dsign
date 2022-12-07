import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Types "./types";

import Logger "canister:logger";

actor FavoriteMain {
	type ErrDeleteFavorite = Types.ErrDeleteFavorite;
	type ErrSaveFavorite = Types.ErrSaveFavorite;
	type FavoriteID = Types.FavoriteID;
	type FavoriteCanisterID = Types.FavoriteCanisterID;
	type FavoriteIDStorage = Types.FavoriteIDStorage;
	type SnapPublic = Types.SnapPublic;

	type FavoriteActor = Types.FavoriteActor;

	let ACTOR_NAME : Text = "FavoriteMain";
	let VERSION : Nat = 1;

	var user_canisters_ref : HashMap.HashMap<Principal, FavoriteIDStorage> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var user_canisters_ref_storage : [var (Principal, [(FavoriteCanisterID, [FavoriteID])])] = [var];

	stable var favorite_canister_id : Text = "";

	// ------------------------- FAVORITES MANAGEMENT -------------------------
	public shared ({ caller }) func save_snap(snap : SnapPublic) : async Result.Result<Text, ErrSaveFavorite> {
		let tags = [ACTOR_NAME, "save_snap"];

		//todo: args security checks

		var user_favorite_ids_storage : FavoriteIDStorage = HashMap.HashMap(0, Text.equal, Text.hash);
		switch (user_canisters_ref.get(caller)) {
			case (?user_favorite_ids_storage_) {
				user_favorite_ids_storage := user_favorite_ids_storage_;
			};
			case (_) {
				return #err(#UserNotFound(true));
			};
		};

		var favorite_ids = Buffer.Buffer<FavoriteID>(0);
		var favorite_ids_found = false;
		switch (user_favorite_ids_storage.get(favorite_canister_id)) {
			case (?favorite_ids_) {
				ignore Logger.log_event(tags, debug_show ("favorite_ids found"));

				favorite_ids := Buffer.fromArray(favorite_ids_);
				favorite_ids_found := true;
			};
			case (_) {
				ignore Logger.log_event(tags, debug_show ("favorite_ids NOT found"));
			};
		};

		let favorite_actor = actor (favorite_canister_id) : FavoriteActor;

		// save snap to as favorite
		switch (await favorite_actor.save_snap(snap, caller)) {
			case (#err err) {
				return #err(#ErrorCall(debug_show (err)));
			};
			case (#ok snap) {
				favorite_ids.add(snap.id);
				user_favorite_ids_storage.put(favorite_canister_id, Buffer.toArray(favorite_ids));

				#ok("Saved Favorite");
			};
		};
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	// ------------------------- SYSTEM METHODS -------------------------
	system func preupgrade() {
		var anon_principal = Principal.fromText("2vxsx-fae");
		user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));

		var index = 0;
		for ((user_principal, favorite_ids_storage) in user_canisters_ref.entries()) {

			user_canisters_ref_storage[index] := (
				user_principal,
				Iter.toArray(favorite_ids_storage.entries())
			);

			index += 1;
		};
	};

	system func postupgrade() {
		var user_canisters_ref_temp : HashMap.HashMap<Principal, FavoriteIDStorage> = HashMap.HashMap(
			0,
			Principal.equal,
			Principal.hash
		);

		for ((user_principal, favorite_ids_storage) in user_canisters_ref_storage.vals()) {
			var favorite_ids_storage_temp : FavoriteIDStorage = HashMap.HashMap(
				0,
				Text.equal,
				Text.hash
			);

			for ((favorite_canister_id, snap_ids) in favorite_ids_storage.vals()) {
				favorite_ids_storage_temp.put(favorite_canister_id, snap_ids);
			};

			user_canisters_ref_temp.put(user_principal, favorite_ids_storage_temp);
		};

		user_canisters_ref := user_canisters_ref_temp;

		var anon_principal = Principal.fromText("2vxsx-fae");
		user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));
	};
};
