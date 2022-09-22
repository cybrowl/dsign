import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Result "mo:base/Result";

import Assets "../service_assets/Assets";
import FileAssetChunks "canister:assets_file_chunks";
import ImageAssets "../service_assets_img/ImageAssets";
import ImageAssetStaging "canister:assets_img_staging";
import Logger "canister:logger";
import Snap "Snap";

import Types "./types";

actor SnapMain {
	type AssetsActor = Types.AssetsActor;
	type CreateAssetArgs = Types.CreateAssetArgs;
	type CreateSnapArgs = Types.CreateSnapArgs;
	type CreateSnapErr = Types.CreateSnapErr;
	type DeleteSnapsErr = Types.DeleteSnapsErr;
	type GetAllSnapsErr = Types.GetAllSnapsErr;
	type ICInterface = Types.ICInterface;
	type ICInterfaceStatusResponse = Types.ICInterfaceStatusResponse;
	type ImageAssetsActor = Types.ImageAssetsActor;
	type ImageRef = Types.ImageRef;
	type Snap = Types.Snap;
	type SnapActor = Types.SnapActor;
	type SnapCanisterID = Types.SnapCanisterID;
	type SnapIDStorage = Types.SnapIDStorage;
	type SnapID = Types.SnapID;
	type Username = Types.Username;
	type UserPrincipal = Types.UserPrincipal;

	let ACTOR_NAME : Text = "SnapMain";
	let CYCLE_AMOUNT : Nat = 100_000_0000_000;
	let VERSION : Nat = 1;

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

	private let ic : ICInterface = actor "aaaaa-aa";

	// ------------------------- Snaps Management -------------------------
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

	public shared ({ caller }) func create_snap(args : CreateSnapArgs) : async Result.Result<Snap, CreateSnapErr> {
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
				return #err(#ErrorCall(debug_show (err)));
			};
			case (#ok snap) {
				snap_ids.add(snap.id);
				if (snap_ids_found == false) {
					user_snap_ids_storage.put(snap_canister_id, snap_ids.toArray());
				};

				//TODO: remove owner from snap
				#ok(snap);
			};
		};
	};

	public shared ({ caller }) func delete_snaps(snapIds : [SnapID]) : async Result.Result<Text, DeleteSnapsErr> {
		let tags = [ACTOR_NAME, "delete_snaps"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_snap_ids_storage) {
				for ((canister_id, snap_ids) in user_snap_ids_storage.entries()) {
					let snap_actor = actor (canister_id) : SnapActor;

					//todo: make sure user owns the snap_ids
					// all snapIds exist in snap_ids

					let snaps = await snap_actor.get_all_snaps(snapIds);

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

					await snap_actor.delete_snaps(snapIds);

					//todo: remove snap ids from snap_canister_ids
				};

				return #ok("delete_snaps");
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	// public shared ({ caller }) func update_snap_project(
	// 	snaps_ref : [SnapRef],
	// 	project_ref : ProjectRef
	// ) : async Result.Result<Text, Text> {
	// 	switch (user_canisters_ref.get(caller)) {
	// 		case (?snap_canister_ids) {
	// 			//todo: make sure user owns the snap_ids

	// 			let snap_actor = actor (snap.canister_id) : SnapActor;
	// 			ignore snap_actor.update_snap_project([snap_ref], project_ref);
	// 		};
	// 		case (_) {
	// 			#err(#UserNotFound);
	// 		};
	// 	};
	// };

	public shared ({ caller }) func get_all_snaps() : async Result.Result<[Snap], GetAllSnapsErr> {
		let tags = [ACTOR_NAME, "get_all_snaps"];

		switch (user_canisters_ref.get(caller)) {
			case (?snap_canister_ids) {
				let all_snaps = Buffer.Buffer<Snap>(0);

				for ((canister_id, snap_ids) in snap_canister_ids.entries()) {
					let snap_actor = actor (canister_id) : SnapActor;
					let snaps = await snap_actor.get_all_snaps(snap_ids);

					for (snap in snaps.vals()) {
						all_snaps.add(snap);
					};
				};

				return #ok(all_snaps.toArray());
			};
			case (_) {
				#err(#UserNotFound(true));
			};
		};
	};

	//todo: get all snaps from project

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	private func create_assets_canister(snap_main_principal : Principal, is_prod : Bool) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let assets_actor = await Assets.Assets(snap_main_principal, is_prod);
		let principal = Principal.fromActor(assets_actor);

		assets_canister_id := Principal.toText(principal);
	};

	private func create_image_assets_canister(snap_main_principal : Principal, is_prod : Bool) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let image_assets_actor = await ImageAssets.ImageAssets(snap_main_principal, is_prod);
		let principal = Principal.fromActor(image_assets_actor);

		image_assets_canister_id := Principal.toText(principal);
	};

	private func create_snap_canister(snap_main_principal : Principal) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let snap_actor = await Snap.Snap(snap_main_principal);
		let principal = Principal.fromActor(snap_actor);

		snap_canister_id := Principal.toText(principal);
	};

	public shared (msg) func initialize_canisters() : async () {
		let tags = [ACTOR_NAME, "initialize_canisters"];
		let snap_main_principal = Principal.fromActor(SnapMain);
		let is_prod = Text.equal(
			Principal.toText(snap_main_principal),
			"lyswl-7iaaa-aaaag-aatya-cai"
		);

		// create assets canister
		if (assets_canister_id.size() < 1) {
			await create_assets_canister(snap_main_principal, is_prod);

			ignore Logger.log_event(
				tags,
				debug_show (("created, assets_canister_id: ", assets_canister_id))
			);
		} else {
			ignore Logger.log_event(
				tags,
				debug_show (("exists, assets_canister_id: ", assets_canister_id))
			);
		};

		// create image assets canister
		if (image_assets_canister_id.size() < 1) {
			await create_image_assets_canister(snap_main_principal, is_prod);

			ignore Logger.log_event(
				tags,
				debug_show (("created, image_assets_canister_id: ", image_assets_canister_id))
			);
		} else {
			ignore Logger.log_event(
				tags,
				debug_show (("exists, image_assets_canister_id: ", image_assets_canister_id))
			);
		};

		// create snap canister
		if (snap_canister_id.size() < 1) {
			await create_snap_canister(snap_main_principal);

			ignore Logger.log_event(
				tags,
				debug_show (("created, snap_canister_id: ", snap_canister_id))
			);
		} else {
			ignore Logger.log_event(
				tags,
				debug_show (("exists, snap_canister_id: ", snap_canister_id))
			);
		};
	};

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
			await ic.install_code({ arg = arg; wasm_module = wasm_module; mode = #upgrade; canister_id = canister_id });

			return "success";
		};

		return "not_authorized";
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
