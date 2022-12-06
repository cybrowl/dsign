import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";

import Assets "../service_assets/Assets";
import CanisterChildLedger "canister:canister_child_ledger";
import FileAssetChunks "canister:assets_file_chunks";
import ImageAssets "../service_assets_img/ImageAssets";
import ImageAssetStaging "canister:assets_img_staging";
import Logger "canister:logger";
import Snap "Snap";

import Types "./types";
import CanisterLedgerTypes "../types/canister_child_ledger.types";
import Utils "../utils/utils";

actor SnapMain {
	type CreateAssetArgs = Types.CreateAssetArgs;
	type CreateSnapArgs = Types.CreateSnapArgs;
	type ErrCreateSnap = Types.ErrCreateSnap;
	type ErrDeleteSnaps = Types.ErrDeleteSnaps;
	type ErrGetAllSnaps = Types.ErrGetAllSnaps;
	type ICInterface = Types.ICInterface;
	type ICInterfaceStatusResponse = Types.ICInterfaceStatusResponse;
	type ImageRef = Types.ImageRef;
	type InitArgs = Types.InitArgs;
	type Snap = Types.Snap;
	type SnapPublic = Types.SnapPublic;
	type SnapCanisterID = Types.SnapCanisterID;
	type SnapID = Types.SnapID;
	type SnapIDStorage = Types.SnapIDStorage;
	type UserPrincipal = Types.UserPrincipal;

	type AssetsActor = Types.AssetsActor;
	type ImageAssetsActor = Types.ImageAssetsActor;
	type SnapActor = Types.SnapActor;

	type CanisterChild = CanisterLedgerTypes.CanisterChild;

	let ACTOR_NAME : Text = "SnapMain";
	let CYCLE_AMOUNT : Nat = 100_000_0000_000;
	let VERSION : Nat = 2;

	var user_canisters_ref : HashMap.HashMap<UserPrincipal, SnapIDStorage> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var user_canisters_ref_storage : [var (UserPrincipal, [(SnapCanisterID, [SnapID])])] = [var];

	// holds data until filled
	// once filled, a new canister is created and assigned
	stable var assets_canister_id : Text = "";
	stable var image_assets_canister_id : Text = "";
	stable var snap_canister_id : Text = "";

	// this doesn't change after init
	stable var project_main_canister_id : Text = "";

	private let ic : ICInterface = actor "aaaaa-aa";

	// ------------------------- SNAPS MANAGEMENT -------------------------
	public shared ({ caller }) func create_user_snap_storage() : async Bool {
		let tags = [ACTOR_NAME, "create_user_snap_storage"];

		switch (user_canisters_ref.get(caller)) {
			case (?snap_canister_ids) {
				ignore Logger.log_event(tags, "exists, user_snap_storage");

				return false;
			};
			case (_) {
				var snap_ids_storage : SnapIDStorage = HashMap.HashMap(
					0,
					Text.equal,
					Text.hash
				);

				user_canisters_ref.put(caller, snap_ids_storage);

				ignore Logger.log_event(tags, "created, user_snap_storage");

				return true;
			};
		};
	};

	public shared ({ caller }) func create_snap(args : CreateSnapArgs) : async Result.Result<Text, ErrCreateSnap> {
		let tags = [ACTOR_NAME, "create_snap"];
		let is_anonymous = Principal.isAnonymous(caller);
		let has_image = args.img_asset_ids.size() > 0;
		let too_many_images = args.img_asset_ids.size() > 4;

		if (is_anonymous == true) {
			return #err(#UserAnonymous);
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

		// save images from img_asset_ids
		let image_ref : ImageRef = { canister_id = ""; id = ""; url = "" };
		var images_ref = [image_ref];
		switch (await image_assets_actor.save_images(args.img_asset_ids, "snap", caller)) {
			case (#err err) {
				ignore Logger.log_event(
					tags,
					debug_show ("image_assets_actor.save_images", err)
				);

				return #err(#ErrorCall(debug_show (err)));
			};
			case (#ok images_ref_) {
				images_ref := images_ref_;

				ignore ImageAssetStaging.delete_assets(args.img_asset_ids, caller);
			};
		};

		// create asset from chunks
		var file_asset = { canister_id = ""; id = ""; url = ""; is_public = false };
		switch (args.file_asset) {
			case null {};
			case (?fileAsset) {
				let file_asset_args : CreateAssetArgs = {
					chunk_ids = fileAsset.chunk_ids;
					content_type = fileAsset.content_type;
					is_public = fileAsset.is_public;
					principal = caller;
				};

				switch (await assets_actor.create_asset_from_chunks(file_asset_args)) {
					case (#err err) {
						ignore Logger.log_event(
							tags,
							debug_show ("assets_actor.create_asset_from_chunks", err)
						);

						return #err(#ErrorCall(debug_show (err)));
					};
					case (#ok file_asset_) {
						file_asset := file_asset_;

						ignore FileAssetChunks.delete_chunks(fileAsset.chunk_ids, caller);
					};
				};
			};
		};

		// save snap
		switch (await snap_actor.create_snap(args, images_ref, file_asset, caller)) {
			case (#err err) {
				ignore Logger.log_event(
					tags,
					debug_show ("snap_actor.create_snap", err)
				);

				return #err(#ErrorCall(debug_show (err)));
			};
			case (#ok snap) {
				snap_ids.add(snap.id);
				user_snap_ids_storage.put(snap_canister_id, Buffer.toArray(snap_ids));

				#ok("Created Snap");
			};
		};
	};

	public shared ({ caller }) func delete_snaps(snap_ids_delete : [SnapID]) : async Result.Result<Text, ErrDeleteSnaps> {
		let tags = [ACTOR_NAME, "delete_snaps"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_snap_ids_storage) {
				let my_ids = Utils.get_all_ids(user_snap_ids_storage);
				let matches = Utils.all_ids_match(my_ids, snap_ids_delete);

				if (matches.all_match == false) {
					return #err(#SnapIdsDoNotMatch);
				};

				for ((canister_id, snap_ids) in user_snap_ids_storage.entries()) {
					let snap_actor = actor (canister_id) : SnapActor;
					let snaps = await snap_actor.get_all_snaps(snap_ids_delete);

					for (snap in snaps.vals()) {
						if (Text.size(snap.file_asset.canister_id) > 1) {
							let assets_actor = actor (snap.file_asset.canister_id) : AssetsActor;
							ignore assets_actor.delete_asset(snap.file_asset.id);
						};

						for (image in snap.images.vals()) {
							if (Text.size(image.canister_id) > 1) {
								let image_assets_actor = actor (image.canister_id) : ImageAssetsActor;
								ignore image_assets_actor.delete_image(image.id);
							};
						};
					};

					await snap_actor.delete_snaps(snap_ids_delete);

					let snap_ids_not_deleted = Utils.get_non_exluded_ids(
						snap_ids,
						snap_ids_delete
					);

					user_snap_ids_storage.put(canister_id, snap_ids_not_deleted);
				};

				return #ok("Deleted Snaps");
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	//TODO: update_snap_likes

	public shared ({ caller }) func get_all_snaps() : async Result.Result<[SnapPublic], ErrGetAllSnaps> {
		let log_tags = [ACTOR_NAME, "get_all_snaps"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_snap_ids_storage) {
				let all_snaps = Buffer.Buffer<SnapPublic>(0);

				for ((canister_id, snap_ids) in user_snap_ids_storage.entries()) {
					let snap_actor = actor (canister_id) : SnapActor;
					let snaps = await snap_actor.get_all_snaps(snap_ids);

					ignore Logger.log_event(
						log_tags,
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

	public shared ({ caller }) func get_all_snaps_without_project() : async Result.Result<[SnapPublic], ErrGetAllSnaps> {
		let tags = [ACTOR_NAME, "get_all_snaps_without_project"];

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

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	// CREATE CANISTER
	private func create_assets_canister(snap_main_principal : Principal, is_prod : Bool) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let assets_actor = await Assets.Assets(snap_main_principal, is_prod);
		let principal = Principal.fromActor(assets_actor);

		assets_canister_id := Principal.toText(principal);

		let canister_child : CanisterChild = {
			created = Time.now();
			id = assets_canister_id;
			name = "assets";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterChildLedger.save_canister(canister_child);
	};

	private func create_image_assets_canister(snap_main_principal : Principal, is_prod : Bool) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let image_assets_actor = await ImageAssets.ImageAssets(snap_main_principal, is_prod);
		let principal = Principal.fromActor(image_assets_actor);

		image_assets_canister_id := Principal.toText(principal);

		let canister_child : CanisterChild = {
			created = Time.now();
			id = image_assets_canister_id;
			name = "image_assets";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterChildLedger.save_canister(canister_child);
	};

	private func create_snap_canister(
		snap_main_principal : Principal,
		project_main_principal : Principal,
		is_prod : Bool
	) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let snap_actor = await Snap.Snap(
			snap_main_principal,
			project_main_principal
		);

		let principal = Principal.fromActor(snap_actor);
		snap_canister_id := Principal.toText(principal);

		let canister_child : CanisterChild = {
			created = Time.now();
			id = snap_canister_id;
			name = "snap";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterChildLedger.save_canister(canister_child);
	};

	// INIT CANISTERS
	public shared (msg) func initialize_canisters(args : InitArgs) : async () {
		let tags = [ACTOR_NAME, "initialize_canisters"];
		let snap_main_principal = Principal.fromActor(SnapMain);

		let is_prod = Text.equal(
			Principal.toText(snap_main_principal),
			"lyswl-7iaaa-aaaag-aatya-cai"
		);

		let has_assets_canister_id : Bool = assets_canister_id.size() > 0;
		let has_image_assets_canister_id : Bool = image_assets_canister_id.size() > 0;
		let has_snap_canister_id : Bool = snap_canister_id.size() > 0;
		let has_project_main_canister_id : Bool = project_main_canister_id.size() > 0;

		if (has_project_main_canister_id == false) {
			switch (args.project_main_canister_id) {
				case (null) {
					project_main_canister_id := "";

					ignore Logger.log_event(
						tags,
						debug_show (("project_main_canister_id NOT found"))
					);
				};
				case (?project_main_canister_id_) {
					project_main_canister_id := project_main_canister_id_;
				};
			};
		};

		let project_main_principal = Principal.fromText(project_main_canister_id);

		// create canisters
		if (has_assets_canister_id == false) {
			await create_assets_canister(snap_main_principal, is_prod);

			ignore Logger.log_event(
				tags,
				debug_show (("created, assets_canister_id: ", assets_canister_id))
			);
		};

		if (has_image_assets_canister_id == false) {
			await create_image_assets_canister(snap_main_principal, is_prod);

			ignore Logger.log_event(
				tags,
				debug_show (("created, image_assets_canister_id: ", image_assets_canister_id))
			);
		};

		if (has_snap_canister_id == false) {
			await create_snap_canister(snap_main_principal, project_main_principal, is_prod);

			ignore Logger.log_event(
				tags,
				debug_show (("created, snap_canister_id: ", snap_canister_id))
			);
		};

		let child_canisters = {
			assets_canister_id = assets_canister_id;
			image_assets_canister_id = image_assets_canister_id;
			snap_canister_id = snap_canister_id;
		};

		ignore Logger.log_event(
			tags,
			debug_show (("child_canisters: ", child_canisters))
		);
	};

	// UPDATE CHILD CANISTERS
	public shared func get_child_status(canister_id : Text) : async ICInterfaceStatusResponse {
		let principal : Principal = Principal.fromText(canister_id);

		await ic.canister_status({ canister_id = principal });
	};

	public shared ({ caller }) func get_child_controllers(canister_id : Text) : async Text {
		let principal : Principal = Principal.fromText(canister_id);

		let response = await ic.canister_status({ canister_id = principal });

		return debug_show (response.settings.controllers, caller);
	};

	public shared ({ caller }) func install_code(
		canister_id : Principal,
		arg : Blob,
		wasm_module : Blob
	) : async Text {
		let principal = Principal.toText(caller);

		if (Text.equal(principal, "be7if-4i5lo-xnuq5-6ilpw-aedq2-epko6-gdmew-kzcse-7qpey-wztpj-qqe")) {
			await ic.install_code({
				arg = arg;
				wasm_module = wasm_module;
				mode = #reinstall;
				canister_id = canister_id;
			});

			return "success";
		};

		return "not_authorized";
	};

	// ------------------------- SYSTEM METHODS -------------------------
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
