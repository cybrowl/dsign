import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";

import Assets "../service_assets/Assets";
import CanisterIdsLedger "canister:canister_ids_ledger";
import FileAssetStaging "canister:assets_file_staging";
import HealthMetrics "canister:health_metrics";
import ImageAssets "../service_assets_img/ImageAssets";
import ImageAssetStaging "canister:assets_img_staging";
import Logger "canister:logger";
import Profile "canister:profile";
import Snap "Snap";

import Types "./types";
import CanisterIdsLedgerTypes "../types/canidster_ids_ledger.types";
import HealthMetricsTypes "../types/health_metrics.types";

import Utils "../utils/utils";
import UtilsShared "../utils/utils";

actor SnapMain {
	type CreateAssetArgs = Types.CreateAssetArgs;
	type CreateSnapArgs = Types.CreateSnapArgs;
	type ErrCreateSnap = Types.ErrCreateSnap;
	type ErrDeleteSnaps = Types.ErrDeleteSnaps;
	type ErrGetAllSnaps = Types.ErrGetAllSnaps;
	type ICInterface = Types.ICInterface;
	type ICInterfaceStatusResponse = Types.ICInterfaceStatusResponse;
	type ImageRef = Types.ImageRef;
	type ProjectRef = Types.ProjectRef;
	type Snap = Types.Snap;
	type SnapRef = Types.SnapRef;
	type SnapCanisterID = Types.SnapCanisterID;
	type SnapID = Types.SnapID;
	type SnapIDStorage = Types.SnapIDStorage;
	type SnapPublic = Types.SnapPublic;
	type UserPrincipal = Types.UserPrincipal;

	type AssetsActor = Types.AssetsActor;
	type ImageAssetsActor = Types.ImageAssetsActor;
	type ProjectActor = Types.ProjectActor;
	type SnapActor = Types.SnapActor;

	type CanisterInfo = CanisterIdsLedgerTypes.CanisterInfo;
	type Payload = HealthMetricsTypes.Payload;

	let ACTOR_NAME : Text = "SnapMain";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;
	let VERSION : Nat = 4;

	var user_canisters_ref : HashMap.HashMap<UserPrincipal, SnapIDStorage> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var user_canisters_ref_storage : [var (UserPrincipal, [(SnapCanisterID, [SnapID])])] = [var];

	//note: doesn't change after init
	stable var project_main_canister_id : Text = "";
	stable var favorite_main_canister_id : Text = "";

	//note: this changes as space is filled
	stable var assets_canister_id : Text = "";
	stable var image_assets_canister_id : Text = "";
	stable var snap_canister_id : Text = "";

	private let ic : ICInterface = actor "aaaaa-aa";

	// ------------------------- Snaps Methods -------------------------
	public shared ({ caller }) func create_user_snap_storage() : async Bool {
		let tags = [("actor_name", ACTOR_NAME), ("method", "create_user_snap_storage")];

		switch (user_canisters_ref.get(caller)) {
			case (?snap_canister_ids) {
				ignore Logger.log_event(tags, "exists, user_snap_storage");

				return false;
			};
			case (_) {
				switch (await Profile.get_username_public(caller)) {
					case (#ok(username)) {
						var snap_ids_storage : SnapIDStorage = HashMap.HashMap(
							0,
							Text.equal,
							Text.hash
						);

						user_canisters_ref.put(caller, snap_ids_storage);

						ignore Logger.log_event(tags, "created, user_snap_storage");

						return true;
					};
					case (#err(_)) {
						ignore Logger.log_event(tags, "no username");
						return false;
					};
				};
			};
		};
	};

	public shared ({ caller }) func create_snap(snap_info : CreateSnapArgs) : async Result.Result<Text, ErrCreateSnap> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "create_snap")];

		let is_anonymous = Principal.isAnonymous(caller);
		let has_image = snap_info.img_asset_ids.size() > 0;
		let too_many_images = snap_info.img_asset_ids.size() > 4;

		if (is_anonymous == true) {
			return #err(#UserAnonymous);
		};

		if (snap_info.title.size() > 100) {
			return #err(#TitleTooLarge);
		};

		switch (snap_info.file_asset) {
			case (null) {};
			case (?file) {
				if (file.content_type.size() > 50) {
					return #err(#FileTypeTooLarge);
				};
			};
		};

		if (has_image == false) {
			return #err(#NoImageToSave);
		};

		if (too_many_images == true) {
			return #err(#FourImagesMax);
		};

		var user_snap_ids_storage : SnapIDStorage = HashMap.HashMap(0, Text.equal, Text.hash);
		switch (user_canisters_ref.get(caller)) {
			case (?user_snap_ids_storage_) {
				user_snap_ids_storage := user_snap_ids_storage_;
			};
			case (_) {
				return #err(#UserNotFound);
			};
		};

		// get snap ids from current canister id
		var snap_ids = Buffer.Buffer<SnapID>(0);
		var snap_ids_found = false;
		switch (user_snap_ids_storage.get(snap_canister_id)) {
			case (?snap_ids_) {
				ignore Logger.log_event(
					tags,
					debug_show ("snap_ids found")
				);

				snap_ids := Buffer.fromArray(snap_ids_);
				snap_ids_found := true;
			};
			case (_) {
				ignore Logger.log_event(tags, debug_show ("snap_ids NOT found"));
			};
		};

		let assets_actor = actor (assets_canister_id) : AssetsActor;
		let image_assets_actor = actor (image_assets_canister_id) : ImageAssetsActor;
		let snap_actor = actor (snap_canister_id) : SnapActor;
		let project_actor = actor (snap_info.project.canister_id) : ProjectActor;

		// save images from img_asset_ids
		let image_ref : ImageRef = { canister_id = ""; id = ""; url = "" };
		var images_ref = [image_ref];
		switch (await image_assets_actor.save_images(snap_info.img_asset_ids, "snap", caller)) {
			case (#err err) {
				ignore Logger.log_event(
					tags,
					debug_show ("image_assets_actor.save_images", err)
				);

				return #err(#ErrorCall(debug_show (err)));
			};
			case (#ok images_ref_) {
				images_ref := images_ref_;

				ignore ImageAssetStaging.delete_assets(snap_info.img_asset_ids, caller);
			};
		};

		// create asset from chunks
		var file_asset = { canister_id = ""; id = ""; file_name = ""; url = ""; is_public = false };
		switch (snap_info.file_asset) {
			case null {};
			case (?fileAsset) {
				let file_asset_snap_info : CreateAssetArgs = {
					chunk_ids = fileAsset.chunk_ids;
					content_type = fileAsset.content_type;
					is_public = fileAsset.is_public;
					principal = caller;
				};

				switch (await assets_actor.create_asset_from_chunks(file_asset_snap_info)) {
					case (#err err) {
						ignore Logger.log_event(
							tags,
							debug_show ("assets_actor.create_asset_from_chunks", err)
						);

						return #err(#ErrorCall(debug_show (err)));
					};
					case (#ok file_asset_) {
						file_asset := file_asset_;

						ignore FileAssetStaging.delete_chunks(fileAsset.chunk_ids, caller);
					};
				};
			};
		};

		// save snap
		switch (await snap_actor.create_snap(snap_info, images_ref, file_asset, caller)) {
			case (#err err) {
				ignore Logger.log_event(
					tags,
					debug_show ("snap_actor.create_snap", err)
				);

				return #err(#ErrorCall(debug_show (err)));
			};
			case (#ok snap) {
				snap_ids.add(snap.id);

				let snap_ref = {
					id = snap.id;
					canister_id = snap.canister_id;
				};

				// add snap to project
				switch (await project_actor.add_snaps_to_project([snap_ref], snap_info.project.id, caller)) {
					case (#err err) {
						ignore Logger.log_event(
							tags,
							debug_show ("project_actor.add_snaps_to_project", err)
						);
					};
					case (#ok project) {
						//TODO: call Snap.add_project_to_snaps
						ignore Logger.log_event(
							tags,
							debug_show ("project_actor.add_snaps_to_project", debug_show (project))
						);
					};
				};

				user_snap_ids_storage.put(snap_canister_id, Buffer.toArray(snap_ids));

				#ok("Created Snap");
			};
		};
	};

	public shared ({ caller }) func delete_snaps(snap_ids_delete : [SnapID], project : ProjectRef) : async Result.Result<Text, ErrDeleteSnaps> {
		let tags = [ACTOR_NAME, "delete_snaps"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_snap_ids_storage) {
				let my_ids = Utils.get_all_ids(user_snap_ids_storage);
				let matches = Utils.all_ids_match(my_ids, snap_ids_delete);
				let project_actor = actor (project.canister_id) : ProjectActor;

				// Owner Check
				if (matches.all_match == false) {
					return #err(#NotOwnerOfSnaps);
				};

				switch (await project_actor.owner_check(project.id, caller)) {
					case (true) {};
					case (false) {
						return #err(#NotOwnerOfProject);
					};
				};

				var snap_refs = Buffer.Buffer<SnapRef>(0);

				for ((canister_id, snap_ids) in user_snap_ids_storage.entries()) {
					let snap_actor = actor (canister_id) : SnapActor;
					let snaps = await snap_actor.get_all_snaps(snap_ids_delete);

					for (snap in snaps.vals()) {
						let snap_ref = {
							id = snap.id;
							canister_id = snap.canister_id;
						};

						snap_refs.add(snap_ref);

						if (Text.size(snap.file_asset.canister_id) > 1) {
							let assets_actor = actor (snap.file_asset.canister_id) : AssetsActor;
							ignore assets_actor.delete_asset(snap.file_asset.id);
						};

						// TODO: add images to a queue to be deleted later

						// for (image in snap.images.vals()) {
						//     if (Text.size(image.canister_id) > 1) {
						//         let image_assets_actor = actor (image.canister_id) : ImageAssetsActor;
						//         ignore image_assets_actor.delete_image(image.id);
						//     };
						// };
					};

					await snap_actor.delete_snaps(snap_ids_delete);

					let snap_ids_not_deleted = Utils.get_non_exluded_ids(
						snap_ids,
						snap_ids_delete
					);

					user_snap_ids_storage.put(canister_id, snap_ids_not_deleted);
				};

				ignore project_actor.delete_snaps_from_project(Buffer.toArray(snap_refs), project.id, caller);

				return #ok("Deleted Snaps");
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	//TODO: update_snap_likes

	public shared ({ caller }) func get_all_snaps() : async Result.Result<[SnapPublic], ErrGetAllSnaps> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "get_all_snaps")];

		switch (user_canisters_ref.get(caller)) {
			case (?user_snap_ids_storage) {
				let all_snaps = Buffer.Buffer<SnapPublic>(0);

				for ((canister_id, snap_ids) in user_snap_ids_storage.entries()) {
					let snap_actor = actor (canister_id) : SnapActor;
					let snaps = await snap_actor.get_all_snaps(snap_ids);

					ignore Logger.log_event(
						tags,
						debug_show ("snap_ids: ", snap_ids)
					);

					for (snap in snaps.vals()) {
						all_snaps.add(snap);
					};
				};

				return #ok(Buffer.toArray(all_snaps));
			};
			case (_) {
				#err(#UserNotFound(true));
			};
		};
	};

	public shared ({ caller }) func get_snap(id : SnapID, canister_id : SnapCanisterID) : async Result.Result<SnapPublic, Text> {
		let tags = [ACTOR_NAME, "get_snap"];

		if (id.size() == 0 or id.size() > 40) {
			return #err("Snap ID is invalid");
		};

		if (canister_id.size() == 0 or canister_id.size() > 40) {
			return #err("Snap Canister ID is invalid");
		};

		let snap_actor = actor (canister_id) : SnapActor;
		let snap = await snap_actor.get_all_snaps([id]);

		return #ok(snap[0]);
	};

	public shared ({ caller }) func get_all_snaps_without_project() : async Result.Result<[SnapPublic], ErrGetAllSnaps> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "get_all_snaps_without_project")];

		//TODO: add username as optional arg
		//TODO: if username is provided it should replace caller

		switch (user_canisters_ref.get(caller)) {
			case (?user_snap_ids_storage) {
				let all_snaps = Buffer.Buffer<SnapPublic>(0);

				for ((canister_id, snap_ids) in user_snap_ids_storage.entries()) {
					let snap_actor = actor (canister_id) : SnapActor;
					let snaps = await snap_actor.get_all_snaps(snap_ids);

					ignore Logger.log_event(
						tags,
						debug_show ("snap_ids: ", snap_ids)
					);

					for (snap in snaps.vals()) {
						switch (snap.project) {
							case (null) {
								all_snaps.add(snap);
							};
							case (_) {
								// do nothing
							};
						};
					};
				};
				return #ok(Buffer.toArray(all_snaps));

			};
			case (_) {
				#err(#UserNotFound(true));
			};
		};

	};

	public shared ({ caller }) func get_snap_ids() : async Result.Result<[SnapID], Text> {
		let tags = [ACTOR_NAME, "get_snap_ids"];

		switch (user_canisters_ref.get(caller)) {
			case (?snap_canister_ids) {
				let all_snap_ids = Buffer.Buffer<SnapID>(0);

				for ((canister_id, snap_ids) in snap_canister_ids.entries()) {
					for (snap_id in snap_ids.vals()) {
						all_snap_ids.add(snap_id);
					};
				};

				return #ok(Buffer.toArray(all_snap_ids));
			};
			case (_) {
				return #err("user not found");
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	private func create_assets_canister(is_prod : Bool) : async () {
		let snap_main_principal = Principal.fromActor(SnapMain);

		Cycles.add(CYCLE_AMOUNT);
		let assets_actor = await Assets.Assets(snap_main_principal, is_prod);
		let principal = Principal.fromActor(assets_actor);

		assets_canister_id := Principal.toText(principal);

		let canister_child : CanisterInfo = {
			created = Time.now();
			id = assets_canister_id;
			name = "assets";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterIdsLedger.save_canister(canister_child);
	};

	private func create_image_assets_canister(is_prod : Bool) : async () {
		let snap_main_principal = Principal.fromActor(SnapMain);

		Cycles.add(CYCLE_AMOUNT);
		let image_assets_actor = await ImageAssets.ImageAssets(snap_main_principal, is_prod);
		let principal = Principal.fromActor(image_assets_actor);

		image_assets_canister_id := Principal.toText(principal);

		let canister_child : CanisterInfo = {
			created = Time.now();
			id = image_assets_canister_id;
			name = "image_assets";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterIdsLedger.save_canister(canister_child);
	};

	private func create_snap_canister(is_prod : Bool) : async () {
		let snap_main_principal = Principal.fromActor(SnapMain);
		let project_main_principal = Principal.fromText(project_main_canister_id);
		let favorite_main_principal = Principal.fromText(favorite_main_canister_id);

		Cycles.add(CYCLE_AMOUNT);
		let snap_actor = await Snap.Snap(
			snap_main_principal,
			project_main_principal,
			favorite_main_principal
		);

		let principal = Principal.fromActor(snap_actor);
		snap_canister_id := Principal.toText(principal);

		let canister_child : CanisterInfo = {
			created = Time.now();
			id = snap_canister_id;
			name = "snap";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterIdsLedger.save_canister(canister_child);
	};

	//NOTE: dev only
	public shared (msg) func set_canister_ids({
		project_main : Text;
		favorite_main : Text;
	}) : async Text {
		let tags = [("actor_name", ACTOR_NAME), ("method", "set_canister_ids")];

		let is_prod = Text.equal(
			Principal.toText(Principal.fromActor(SnapMain)),
			"lyswl-7iaaa-aaaag-aatya-cai"
		);

		if (is_prod == false) {
			project_main_canister_id := project_main;
			favorite_main_canister_id := favorite_main;
		};

		ignore Logger.log_event(
			tags,
			"set_canister_ids: " # project_main # "," # favorite_main
		);

		return "set_canister_ids";
	};

	public shared (msg) func initialize_canisters() : async () {
		let tags = [("actor_name", ACTOR_NAME), ("method", "initialize_canisters")];

		let is_prod = Text.equal(
			Principal.toText(Principal.fromActor(SnapMain)),
			"lyswl-7iaaa-aaaag-aatya-cai"
		);

		if (is_prod == true) {
			project_main_canister_id := "nhlnj-vyaaa-aaaag-aay5q-cai";
			favorite_main_canister_id := "a7b5k-xiaaa-aaaag-aa6ja-cai";
		};

		let project_main_principal = Principal.fromText(project_main_canister_id);
		let favorite_main_principal = Principal.fromText(favorite_main_canister_id);

		ignore Logger.log_event(tags, "main_ids: " # project_main_canister_id # "," # favorite_main_canister_id);

		// create canisters
		if (assets_canister_id.size() < 3) {
			await create_assets_canister(is_prod);

			ignore Logger.log_event(tags, "created assets_canister_id: " # assets_canister_id);
		};

		if (image_assets_canister_id.size() < 3) {
			await create_image_assets_canister(is_prod);

			ignore Logger.log_event(tags, "created image_assets_canister_id: " # image_assets_canister_id);
		};

		if (snap_canister_id.size() < 3) {
			await create_snap_canister(is_prod);

			ignore Logger.log_event(tags, "created snap_canister_id: " # snap_canister_id);
		};

		let child_canister_ids = assets_canister_id # "," # image_assets_canister_id # "," # snap_canister_id;

		ignore Logger.log_event(tags, "exists child_canister_ids: " # child_canister_ids);
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
			child_canister_id = Principal.toText(Principal.fromActor(SnapMain));
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

		return "not authorized";
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		var anon_principal = Principal.fromText("2vxsx-fae");
		user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));

		var index = 0;
		for ((user_principal, snap_ids_storage) in user_canisters_ref.entries()) {

			user_canisters_ref_storage[index] := (
				user_principal,
				Iter.toArray(snap_ids_storage.entries())
			);

			index += 1;
		};
	};

	system func postupgrade() {
		var user_canisters_ref_temp : HashMap.HashMap<UserPrincipal, SnapIDStorage> = HashMap.HashMap(
			0,
			Principal.equal,
			Principal.hash
		);

		for ((user_principal, snap_ids_storage) in user_canisters_ref_storage.vals()) {
			var snap_ids_storage_temp : SnapIDStorage = HashMap.HashMap(
				0,
				Text.equal,
				Text.hash
			);

			for ((snap_canister_id, snap_ids) in snap_ids_storage.vals()) {
				snap_ids_storage_temp.put(snap_canister_id, snap_ids);
			};

			user_canisters_ref_temp.put(user_principal, snap_ids_storage_temp);
		};

		user_canisters_ref := user_canisters_ref_temp;

		var anon_principal = Principal.fromText("2vxsx-fae");
		user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));
	};
};
