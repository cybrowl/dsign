import { Buffer; toArray } "mo:base/Buffer";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Rand "mo:base/Random";
import Result "mo:base/Result";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";
import ImageAssetStaging "canister:assets_img_staging";

import Types "./types";
import HealthMetricsTypes "../types/health_metrics.types";

import Utils "./utils";
import UtilsShared "../utils/utils";

actor class ImageAssets(controller : Principal, is_prod : Bool) = this {
	type AssetImg = Types.AssetImg;
	type HttpRequest = Types.HttpRequest;
	type HttpResponse = Types.HttpResponse;
	type ImageID = Types.ImageID;
	type ImageRef = Types.ImageRef;

	type Payload = HealthMetricsTypes.Payload;

	type AssetImgErr = {
		#NotAuthorized;
		#NotOwnerOfAsset;
		#AssetNotFound;
	};

	let ACTOR_NAME : Text = "ImageAssets";
	let VERSION : Nat = 5;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	var image_assets : HashMap.HashMap<ImageID, AssetImg> = HashMap.HashMap(
		0,
		Text.equal,
		Text.hash
	);
	stable var image_assets_stable_storage : [(ImageID, AssetImg)] = [];

	public shared ({ caller }) func save_images(
		img_asset_ids : [Nat],
		asset_type : Text,
		owner : Principal
	) : async Result.Result<[Types.ImageRef], AssetImgErr> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "save_images")];

		if (controller != caller) {
			ignore Logger.log_event(
				tags,
				"Not Authorized: " # Principal.toText(caller)
			);

			return #err(#NotAuthorized);
		};

		let images_ref = Buffer<ImageRef>(0);

		for (asset_id in img_asset_ids.vals()) {
			switch (await ImageAssetStaging.get_asset(asset_id, owner)) {
				case (#ok asset) {
					let canister_id = Principal.toText(Principal.fromActor(this));
					let image_id : ImageID = ULID.toText(se.new());
					image_assets.put(image_id, asset);

					let image_ref = {
						canister_id = canister_id;
						id = image_id;
						url = Utils.generate_image_url(canister_id, image_id, asset_type, is_prod);
					};

					images_ref.add(image_ref);
				};
				case (#err err) {
					switch (err) {
						case (#NotOwnerOfAsset) {

							ignore Logger.log_event(tags, debug_show ("NotOwnerOfAsset"));
							return #err(#NotOwnerOfAsset);
						};
						case (#AssetNotFound) {

							ignore Logger.log_event(tags, debug_show ("AssetNotFound"));
							return #err(#AssetNotFound);
						};
					};
				};
			};
		};

		ignore ImageAssetStaging.delete_assets(img_asset_ids, owner);
		return #ok(toArray(images_ref));
	};

	public shared ({ caller }) func update_image(
		asset_id : Nat,
		stored_asset_id : Text,
		asset_type : Text,
		owner : Principal
	) : async Result.Result<Types.ImageRef, AssetImgErr> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "update_image")];

		if (controller != caller) {
			ignore Logger.log_event(
				tags,
				"Not Authorized: " # Principal.toText(caller)
			);

			return #err(#NotAuthorized);
		};

		switch (await ImageAssetStaging.get_asset(asset_id, owner)) {
			case (#ok asset) {
				let canister_id = Principal.toText(Principal.fromActor(this));
				image_assets.put(stored_asset_id, asset);

				let image_ref = {
					canister_id = canister_id;
					id = stored_asset_id;
					url = Utils.generate_image_url(
						canister_id,
						stored_asset_id,
						asset_type,
						is_prod
					);
				};

				ignore ImageAssetStaging.delete_assets([asset_id], owner);
				return #ok(image_ref);
			};
			case (#err err) {
				switch (err) {
					case (#NotOwnerOfAsset) {

						ignore Logger.log_event(tags, debug_show ("NotOwnerOfAsset"));
						return #err(#NotOwnerOfAsset);
					};
					case (#AssetNotFound) {

						ignore Logger.log_event(tags, debug_show ("AssetNotFound"));
						return #err(#AssetNotFound);
					};
				};
			};
		};
	};

	public shared ({ caller }) func delete_image(image_id : Text) : async () {
		let tags = [("actor_name", ACTOR_NAME), ("method", "delete_image")];

		if (controller != caller) {
			ignore Logger.log_event(
				tags,
				"Not Authorized: " # Principal.toText(caller)
			);

			return ();
		};

		ignore Logger.log_event(tags, debug_show ("image", image_id));
		image_assets.delete(image_id);
	};

	// serves the image to the client when requested via image url
	public shared query func http_request(req : HttpRequest) : async HttpResponse {
		let NOT_FOUND : Blob = Blob.fromArray([0]);

		//TODO: return the correct image type
		let image_id : Text = Utils.get_image_id(req.url);

		switch (image_assets.get(image_id)) {
			case (?image) {
				return {
					status_code = 200;
					headers = [("content-type", "image/png")];
					body = image.data;
				};
			};
			case (_) {
				return {
					status_code = 404;
					headers = [("content-type", "image/png")];
					body = NOT_FOUND;
				};
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("parent", Principal.toText(controller)),
			("canister_id", Principal.toText(Principal.fromActor(this))),
			("image_assets_size", Int.toText(image_assets.size())),
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
				("images_num", image_assets.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(this));
			parent_canister_id = Principal.toText(controller);
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	public query func is_full() : async Bool {
		return UtilsShared.is_full();
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		image_assets_stable_storage := Iter.toArray(image_assets.entries());
	};

	system func postupgrade() {
		image_assets := HashMap.fromIter<ImageID, AssetImg>(
			image_assets_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		image_assets_stable_storage := [];
	};
};
