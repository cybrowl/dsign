import Array "mo:base/Array";
import { Buffer; fromArray; toArray } "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";
import CanisterLedgerTypes "../types/canister_child_ledger.types";

import CanisterChildLedger "canister:canister_child_ledger";
import Favorite "Favorite";
import Logger "canister:logger";

import Utils "../utils/utils";

actor FavoriteMain {
	type ErrDeleteFavorite = Types.ErrDeleteFavorite;
	type ErrGetFavorite = Types.ErrGetFavorite;
	type ErrSaveFavorite = Types.ErrSaveFavorite;
	type FavoriteCanisterID = Types.FavoriteCanisterID;
	type FavoriteID = Types.FavoriteID;
	type FavoriteIDStorage = Types.FavoriteIDStorage;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;

	type FavoriteActor = Types.FavoriteActor;
	type SnapActor = Types.SnapActor;

	type CanisterChild = CanisterLedgerTypes.CanisterChild;

	let ACTOR_NAME : Text = "FavoriteMain";
	let CYCLE_AMOUNT : Nat = 100_000_0000_000;
	let VERSION : Nat = 1;

	var user_canisters_ref : HashMap.HashMap<Principal, FavoriteIDStorage> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var user_canisters_ref_storage : [var (Principal, [(FavoriteCanisterID, [FavoriteID])])] = [var];

	stable var favorite_canister_id : Text = "";

	// ------------------------- FAVORITES MANAGEMENT -------------------------
	public shared ({ caller }) func create_user_favorite_storage() : async Bool {
		let tags = [ACTOR_NAME, "create_user_favorite_storage"];

		switch (user_canisters_ref.get(caller)) {
			case (?favorite_canister_ids) {
				ignore Logger.log_event(tags, "exists, user_favorite_storage");

				return false;
			};
			case (_) {
				var favorite_ids_storage : FavoriteIDStorage = HashMap.HashMap(
					0,
					Text.equal,
					Text.hash
				);

				user_canisters_ref.put(caller, favorite_ids_storage);

				ignore Logger.log_event(tags, "created, user_favorite_storage");

				return true;
			};
		};
	};

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

		var favorite_ids = Buffer<FavoriteID>(0);
		var favorite_ids_found = false;
		switch (user_favorite_ids_storage.get(favorite_canister_id)) {
			case (?favorite_ids_) {
				ignore Logger.log_event(tags, debug_show ("favorite_ids found"));

				favorite_ids := fromArray(favorite_ids_);
				favorite_ids_found := true;
			};
			case (_) {
				ignore Logger.log_event(tags, debug_show ("favorite_ids NOT found"));
			};
		};

		let snap_actor = actor (snap.canister_id) : SnapActor;

		switch (await snap_actor.update_snap_metrics(snap.id)) {
			case (#err err) {
				return #err(#ErrorCall(debug_show ("snap_actor", err)));
			};
			case (#ok snap) {
				let favorite_actor = actor (favorite_canister_id) : FavoriteActor;

				switch (await favorite_actor.save_snap(snap, caller)) {
					case (#err err) {
						return #err(#ErrorCall(debug_show ("favorite_actor", err)));
					};
					case (#ok snap) {
						favorite_ids.add(snap.id);
						user_favorite_ids_storage.put(favorite_canister_id, toArray(favorite_ids));

						#ok("Saved Favorite");
					};
				};
			};
		};
	};

	public shared ({ caller }) func delete_snap(snap_id_delete : SnapID) : async Result.Result<Text, ErrDeleteFavorite> {
		let tags = [ACTOR_NAME, "delete_snap"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_favorites_ids_storage) {
				let my_ids = Utils.get_all_ids(user_favorites_ids_storage);
				let matches = Utils.all_ids_match(my_ids, [snap_id_delete]);

				if (matches.all_match == false) {
					return #err(#FavoriteIdsDoNotMatch(true));
				};

				for ((canister_id, snap_ids) in user_favorites_ids_storage.entries()) {
					let favorite_actor = actor (canister_id) : FavoriteActor;

					ignore favorite_actor.delete_snap(snap_id_delete);

					let snap_ids_not_deleted = Utils.get_non_exluded_ids(
						snap_ids,
						[snap_id_delete]
					);

					user_favorites_ids_storage.put(canister_id, snap_ids_not_deleted);
				};

				return #ok("Deleted Snaps");
			};
			case (_) {
				#err(#UserNotFound(true));
			};
		};
	};

	public shared ({ caller }) func get_all_snaps() : async Result.Result<[SnapPublic], ErrGetFavorite> {
		let tags = [ACTOR_NAME, "get_all_snaps"];

		switch (user_canisters_ref.get(caller)) {
			case (?favorite_canister_ids) {
				let all_snaps = Buffer<SnapPublic>(0);

				for ((canister_id, snap_ids) in favorite_canister_ids.entries()) {
					let favorite_actor = actor (canister_id) : FavoriteActor;

					switch (await favorite_actor.get_all_snaps(snap_ids)) {
						case (#err err) {
							return #err(#ErrorCall(debug_show (err)));
						};
						case (#ok snaps) {
							for (snap in snaps.vals()) {
								all_snaps.add(snap);
							};
						};
					};
				};

				if (all_snaps.size() == 0) {
					return #err(#SnapsEmpty(true));
				};

				return #ok(toArray(all_snaps));
			};
			case (_) {
				return #err(#UserNotFound(true));
			};
		};
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	private func create_favorite_canister(favorite_main_principal : Principal, is_prod : Bool) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let favorite_actor = await Favorite.Favorite(favorite_main_principal);
		let principal = Principal.fromActor(favorite_actor);

		favorite_canister_id := Principal.toText(principal);

		let canister_child : CanisterChild = {
			created = Time.now();
			id = favorite_canister_id;
			name = "favorite";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterChildLedger.save_canister(canister_child);
	};

	public shared (msg) func initialize_canisters() : async Text {
		let tags = [ACTOR_NAME, "initialize_canisters"];
		let favorite_main_principal = Principal.fromActor(FavoriteMain);
		let is_prod = Text.equal(
			Principal.toText(favorite_main_principal),
			"lyswl-7iaaa-aaaag-aatya-cai"
		);

		if (favorite_canister_id.size() > 1) {
			ignore Logger.log_event(
				tags,
				debug_show (("favorite_canister_id already set: ", favorite_canister_id))
			);

			return favorite_canister_id;
		} else {
			ignore Logger.log_event(tags, debug_show ("no arg, creating favorite_canister_id"));

			await create_favorite_canister(favorite_main_principal, is_prod);

			return favorite_canister_id;
		}

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

			for ((favorite_canister_id, favorite_ids) in favorite_ids_storage.vals()) {
				favorite_ids_storage_temp.put(favorite_canister_id, favorite_ids);
			};

			user_canisters_ref_temp.put(user_principal, favorite_ids_storage_temp);
		};

		user_canisters_ref := user_canisters_ref_temp;

		var anon_principal = Principal.fromText("2vxsx-fae");
		user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));
	};
};
