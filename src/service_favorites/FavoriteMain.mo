import { Buffer; fromArray; toArray; removeDuplicates } "mo:base/Buffer";
import Array "mo:base/Array";
import Buff "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CanisterIdsLedgerTypes "../types/canidster_ids_ledger.types";
import HealthMetricsTypes "../types/health_metrics.types";
import Types "./types";

import CanisterIdsLedger "canister:canister_ids_ledger";
import Favorite "Favorite";
import HealthMetrics "canister:health_metrics";
import Profile "canister:profile";
import Logger "canister:logger";

import UtilsShared "../utils/utils";

actor FavoriteMain {
	type ErrDeleteFavorite = Types.ErrDeleteFavorite;
	type ErrGetFavorite = Types.ErrGetFavorite;
	type ErrSaveFavorite = Types.ErrSaveFavorite;
	type FavoriteCanisterID = Types.FavoriteCanisterID;
	type FavoriteID = Types.FavoriteID;
	type FavoriteIDStorage = Types.FavoriteIDStorage;
	type ICInterface = Types.ICInterface;
	type ICInterfaceStatusResponse = Types.ICInterfaceStatusResponse;
	type ProjectRef = Types.ProjectRef;
	type ProjectPublic = Types.ProjectPublic;

	type FavoriteActor = Types.FavoriteActor;
	type ProjectActor = Types.ProjectActor;

	type CanisterInfo = CanisterIdsLedgerTypes.CanisterInfo;
	type Payload = HealthMetricsTypes.Payload;

	let ACTOR_NAME : Text = "FavoriteMain";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;
	let VERSION : Nat = 1;

	var user_canisters_ref : HashMap.HashMap<Principal, FavoriteIDStorage> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var user_canisters_ref_storage : [var (Principal, [(FavoriteCanisterID, [FavoriteID])])] = [var];

	private let ic : ICInterface = actor "aaaaa-aa";

	//note: this changes as space is filled
	stable var favorite_canister_id : Text = "";

	// ------------------------- Favorites Methods -------------------------
	public shared ({ caller }) func create_user_favorite_storage() : async Bool {
		let tags = [("actor_name", ACTOR_NAME), ("method", "create_user_favorite_storage")];

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

	public shared ({ caller }) func save_project(project : ProjectRef) : async Result.Result<Text, ErrSaveFavorite> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "save_project")];

		if (project.id.size() > 50 or project.canister_id.size() > 50) {
			return #err(#ArgsTooLong(true));
		};

		var user_favorite_ids_storage : FavoriteIDStorage = HashMap.HashMap(0, Text.equal, Text.hash);
		switch (user_canisters_ref.get(caller)) {
			case (?user_favorite_ids_storage_) {
				user_favorite_ids_storage := user_favorite_ids_storage_;
			};
			case (_) {
				return #err(#UserNotFound(true));
			};
		};

		let my_ids = UtilsShared.get_all_ids(user_favorite_ids_storage);
		let favorite_id_exists = UtilsShared.some(my_ids, [project.id]);
		if (favorite_id_exists == true) {
			return #err(#ProjectAlreadySaved(true));
		};

		var favorite_ids = Buffer<FavoriteID>(0);
		var favorite_ids_found = false;
		switch (user_favorite_ids_storage.get(favorite_canister_id)) {
			case (?favorite_ids_) {
				ignore Logger.log_event(log_tags, "favorite_ids found");

				favorite_ids := fromArray(favorite_ids_);
				favorite_ids_found := true;
			};
			case (_) {
				ignore Logger.log_event(log_tags, "favorite_ids NOT found");
			};
		};

		let project_actor = actor (project.canister_id) : ProjectActor;
		let favorite_actor = actor (favorite_canister_id) : FavoriteActor;

		switch (await favorite_actor.save_project(project)) {
			case (#err err) {
				ignore Logger.log_event(log_tags, debug_show ("favorite_actor: ", err));

				return #err(#ErrorCall(debug_show ("favorite_actor: ", err)));
			};
			case (#ok projec_ref) {
				ignore project_actor.update_snap_metrics(project.id, #LikeAdd);

				favorite_ids.add(project.id);

				removeDuplicates<FavoriteID>(favorite_ids, Text.compare);

				user_favorite_ids_storage.put(favorite_canister_id, toArray(favorite_ids));

				return #ok("Project Added To Favotires");
			};
		};
	};

	public shared ({ caller }) func delete_project(project : ProjectRef) : async Result.Result<Text, ErrDeleteFavorite> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "delete_project")];

		if (project.id.size() > 50 or project.canister_id.size() > 50) {
			return #err(#ArgsTooLong(true));
		};

		switch (user_canisters_ref.get(caller)) {
			case (?user_favorite_ids_storage) {
				let project_ids = UtilsShared.get_all_ids(user_favorite_ids_storage);
				let matches = UtilsShared.all_ids_match(project_ids, [project.id]);

				if (matches.all_match == false) {
					return #err(#NotOwner(true));
				};

				let favorite_actor = actor (project.canister_id) : FavoriteActor;

				switch (await favorite_actor.delete_project(project.id)) {
					case (#err err) {
						ignore Logger.log_event(log_tags, debug_show ("favorite_actor: ", err));

						return #err(#ErrorCall(debug_show ("favorite_actor: ", err)));
					};
					case (#ok projec_ref) {
						let project_ids_not_deleted = UtilsShared.get_non_exluded_ids(
							project_ids,
							[project.id]
						);

						user_favorite_ids_storage.put(project.canister_id, project_ids_not_deleted);

						return #ok("Favorite Deleted");
					};
				};
			};
			case (_) {
				return #err(#UserNotFound(true));
			};
		};
	};

	public shared ({ caller }) func get_all_projects(username : ?Text) : async Result.Result<[ProjectPublic], ErrGetFavorite> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "get_all_projects")];

		var user_principal = caller;

		switch (username) {
			case (?username) {
				switch (await Profile.get_user_principal_public(username)) {
					case (#err err) {
						//TODO: log error
					};
					case (#ok principal) {
						user_principal := principal;
					};
				};
			};
			case (_) {};
		};

		switch (user_canisters_ref.get(user_principal)) {
			case (?favorite_canister_ids) {
				let all_projects = Buffer<ProjectPublic>(0);

				for ((canister_id, favorite_ids) in favorite_canister_ids.entries()) {
					let favorite_actor = actor (canister_id) : FavoriteActor;

					switch (await favorite_actor.get_all_projects(favorite_ids)) {
						case (#err err) {
							return #err(#ErrorCall(debug_show (err)));
						};
						case (#ok projects) {
							for (project in projects.vals()) {
								all_projects.add(project);
							};
						};
					};
				};

				if (all_projects.size() == 0) {
					return #err(#ProjectsEmpty(true));
				};

				return #ok(toArray(all_projects));
			};
			case (_) {
				return #err(#UserNotFound(true));
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	private func create_favorite_canister(is_prod : Bool) : async () {
		let favorite_main_principal = Principal.fromActor(FavoriteMain);

		Cycles.add(CYCLE_AMOUNT);
		let favorite_actor = await Favorite.Favorite(favorite_main_principal);
		let principal = Principal.fromActor(favorite_actor);

		favorite_canister_id := Principal.toText(principal);

		let canister_child : CanisterInfo = {
			created = Time.now();
			id = favorite_canister_id;
			name = "favorite";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterIdsLedger.save_canister(canister_child);
	};

	public shared (msg) func initialize_canisters() : async Text {
		let tags = [("actor_name", ACTOR_NAME), ("method", "initialize_canisters")];

		let is_prod = Text.equal(
			Principal.toText(Principal.fromActor(FavoriteMain)),
			"a7b5k-xiaaa-aaaag-aa6ja-cai"
		);

		if (favorite_canister_id.size() > 1) {
			ignore Logger.log_event(tags, "exists favorite_canister_id: " # favorite_canister_id);

			return favorite_canister_id;
		} else {
			await create_favorite_canister(is_prod);

			ignore Logger.log_event(tags, "created favorite_canister_id: " # favorite_canister_id);

			return favorite_canister_id;
		};
	};

	public shared func health() : async Payload {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("user_canisters_ref_num", Int.toText(user_canisters_ref.size())),
			("cycles_balance", Int.toText(UtilsShared.get_cycles_balance())),
			("memory_in_mb", Int.toText(UtilsShared.get_memory_in_mb())),
			("heap_in_mb", Int.toText(UtilsShared.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);

		let log_payload : Payload = {
			metrics = [
				("user_can_refs", user_canisters_ref.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(FavoriteMain));
			parent_canister_id = "";
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	public shared ({ caller }) func install_code(
		canister_id : Principal,
		arg : Blob,
		wasm_module : Blob
	) : async Text {
		let principal = Principal.toText(caller);

		if (Text.equal(principal, "isek4-vq7sa-2zqqw-xdzen-h2q5k-f47ix-5nz4o-gltx5-s75cq-63gh6-wae")) {
			await ic.install_code({
				arg = arg;
				wasm_module = wasm_module;
				mode = #upgrade;
				canister_id = canister_id;
			});

			return "success";
		};

		return "not_authorized";
	};

	// ------------------------- System Methods -------------------------
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
