import Array "mo:base/Array";
import Blob "mo:base/Blob";
import { Buffer; toArray } "mo:base/Buffer";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Rand "mo:base/Random";
import Result "mo:base/Result";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import FileAssetStaging "canister:assets_file_staging";
import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";

import HealthMetricsTypes "../types/health_metrics.types";
import Types "./types";

import Utils "./utils";
import UtilsShared "../utils/utils";

actor class Assets(controller : Principal, is_prod : Bool) = this {
	let ACTOR_NAME : Text = "Assets";
	let VERSION : Nat = 3;

	type Payload = HealthMetricsTypes.Payload;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	private var assets : HashMap.HashMap<Text, Types.Asset> = HashMap.HashMap<Text, Types.Asset>(
		0,
		Text.equal,
		Text.hash
	);
	stable var assets_stable_storage : [(Text, Types.Asset)] = [];

	// ------------------------- Create Asset -------------------------
	public shared ({ caller }) func create_asset_from_chunks(args : Types.CreateAssetArgs) : async Result.Result<Types.AssetRef, Text> {
		var asset_data = Buffer<Blob>(0);
		var all_chunks_match_owner : Bool = true;

		var created : Int = 0;
		var owner : Principal = args.principal;
		var file_name : Text = "";
		let data_chunks_size : Nat = 0;
		let asset_id : Text = ULID.toText(se.new());

		if (controller != caller) {
			return #err("Not Authorized");
		};

		// get all chunks and check if owners match
		for (chunk_id in args.chunk_ids.vals()) {
			switch (await FileAssetStaging.get_chunk(chunk_id, args.principal)) {
				case (#ok chunk) {

					asset_data.add(chunk.data);

					if (owner != chunk.owner) {
						all_chunks_match_owner := false;
					};

					created := chunk.created;
					owner := chunk.owner;
					file_name := chunk.file_name;
				};
				case (#err err) {
					//TODO: log error
				};
			};
		};

		if (all_chunks_match_owner == false) {
			return #err("All Chunks Must Match Owner");
		};

		let self = Principal.fromActor(this);
		let canister_id : Text = Principal.toText(self);

		let asset_url = Utils.generate_asset_url({
			asset_id = asset_id;
			canister_id = canister_id;
			is_prod = is_prod;
		});

		let asset : Types.Asset = {
			canister_id = canister_id;
			content_type = args.content_type;
			created = created;
			data_chunks = toArray(asset_data);
			data_chunks_size = asset_data.size();
			file_name = file_name;
			id = asset_id;
			is_public = args.is_public;
			owner = owner;
		};

		assets.put(asset_id, asset);

		ignore FileAssetStaging.delete_chunks(args.chunk_ids, owner);

		let asset_ref : Types.AssetRef = {
			url = asset_url;
			canister_id = canister_id;
			file_name = file_name;
			id = asset_id;
			is_public = args.is_public;
		};

		asset_data.clear();

		#ok(asset_ref);
	};

	public shared ({ caller }) func delete_asset(asset_id : Text) : async () {
		let tags = [("actor_name", ACTOR_NAME), ("method", "delete_asset")];

		if (controller != caller) {
			return ();
		};

		ignore Logger.log_event(tags, debug_show ("asset", asset_id));
		assets.delete(asset_id);
	};

	// ------------------------- Get Asset -------------------------
	public shared query ({ caller }) func http_request(request : Types.HttpRequest) : async Types.HttpResponse {
		let NOT_FOUND : [Nat8] = Blob.toArray(Text.encodeUtf8("Asset Not Found"));

		let asset_id = Utils.get_asset_id(request.url);

		switch (assets.get(asset_id)) {
			case (?asset) {
				let file_name = Text.concat("attachment; filename=", asset.file_name);

				return {
					body = Blob.toArray(asset.data_chunks[0]);
					headers = [
						("Content-Type", asset.content_type),
						("accept-ranges", "bytes"),
						("Content-Disposition", file_name),
						("cache-control", "private, max-age=0")
					];
					status_code = 200;
					streaming_strategy = create_strategy({
						asset_id = asset_id;
						chunk_index = 0;
						data_chunks_size = asset.data_chunks_size;
					});
				};
			};
			case _ {
				return {
					body = NOT_FOUND;
					headers = [];
					status_code = 404;
					streaming_strategy = null;
				};
			};
		};
	};

	private func create_strategy(args : Types.CreateStrategyArgs) : ?Types.StreamingStrategy {
		switch (create_token(args)) {
			case (null) { null };
			case (?token) {
				let self = Principal.fromActor(this);
				let canister_id : Text = Principal.toText(self);
				let canister = actor (canister_id) : actor {
					http_request_streaming_callback : shared () -> async ();
				};

				return ?#Callback({ token; callback = canister.http_request_streaming_callback });
			};
		};
	};

	private func create_token(args : Types.CreateStrategyArgs) : ?Types.StreamingCallbackToken {
		if (args.chunk_index + 1 >= args.data_chunks_size) {
			return null;
		} else {
			let token = {
				asset_id = args.asset_id;
				chunk_index = args.chunk_index + 1;
				content_encoding = "gzip";
			};

			return ?token;
		};
	};

	public shared query ({ caller }) func http_request_streaming_callback(
		st : Types.StreamingCallbackToken
	) : async Types.StreamingCallbackHttpResponse {

		switch (assets.get(st.asset_id)) {
			case (null) throw Error.reject("asset_id not found: " # st.asset_id);
			case (?asset) {
				return {
					token = create_token({
						asset_id = st.asset_id;
						chunk_index = st.chunk_index;
						data_chunks_size = asset.data_chunks_size;
					});
					body = asset.data_chunks[st.chunk_index];
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
			("assets_size", Int.toText(assets.size())),
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
				("assets_num", assets.size()),
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

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		assets_stable_storage := Iter.toArray(assets.entries());
	};

	system func postupgrade() {
		assets := HashMap.fromIter<Text, Types.Asset>(
			assets_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		assets_stable_storage := [];
	};
};
