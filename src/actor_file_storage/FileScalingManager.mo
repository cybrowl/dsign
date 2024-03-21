import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import FileStorage "FileStorage";
import Logger "canister:logger";

import Types "./types";
import ICTypes "../c_types/ic";

import Health "../libs/health";

actor class FileScalingManager(is_prod : Bool, port : Text) = this {
	type FileStorageInfo = Types.FileStorageInfo;
	type Status = Types.Status;
	type ErrInit = Types.ErrInit;

	type FileStorageActor = Types.FileStorageActor;
	type ICManagementActor = ICTypes.Self;

	let { thash } = Map;

	// ------------------------- Variables -------------------------
	let ACTOR_NAME : Text = "FileScalingManager";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;
	let VERSION : Nat = 4;

	stable var file_storage_canister_id : Text = "";

	// ------------------------- Storage Data -------------------------
	private var file_storage_registry = Map.new<Text, FileStorageInfo>();
	stable var file_storage_registry_stable_storage : [(Text, FileStorageInfo)] = [];

	// ------------------------- Actor -------------------------
	private let ic_management_actor : ICManagementActor = actor "aaaaa-aa";

	// ------------------------- File Storage Registry -------------------------
	public query func get_file_storage_registry() : async [FileStorageInfo] {
		return Iter.toArray(Map.vals(file_storage_registry));
	};

	public query func get_file_storage_registry_size() : async Nat {
		return Map.size(file_storage_registry);
	};

	public query func get_current_canister_id() : async Text {
		return file_storage_canister_id;
	};

	public query func get_current_canister() : async ?FileStorageInfo {
		switch (Map.get(file_storage_registry, thash, file_storage_canister_id)) {
			case (?canister) {
				return ?canister;
			};
			case _ {
				return null;
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	// Version
	public query func version() : async Nat {
		return VERSION;
	};

	// Init
	public shared func init() : async Text {
		if (file_storage_canister_id.size() > 3) {
			return file_storage_canister_id;
		} else {
			await create_file_storage_canister();

			return file_storage_canister_id;
		};
	};

	// Upgrade
	public shared ({ caller }) func install_code(
		canister_id : Principal,
		arg : Blob,
		wasm_module : Blob
	) : async Text {
		let caller_principal = Principal.toText(caller);
		let admin_principal = "pimnv-hjnlu-go5zn-6wkn3-xb7l5-al2yp-udeku-genyx-aqgd2-qy4xn-nae";

		if (Text.equal(caller_principal, admin_principal)) {
			await ic_management_actor.install_code({
				arg = arg;
				wasm_module = wasm_module;
				mode = #upgrade;
				canister_id = canister_id;
			});

			return "upgrated";
		} else {
			return "failed to upgrade";
		};
	};

	// Health
	public shared func health() : async () {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("version", Int.toText(VERSION)),
			("file_storage_registry_size", Int.toText(file_storage_registry.size())),
			("cycles_balance", Int.toText(Health.get_cycles_balance())),
			("memory_in_mb", Int.toText(Health.get_memory_in_mb())),
			("heap_in_mb", Int.toText(Health.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);
	};

	// ------------------------- Private Methods -------------------------
	private func create_file_storage_canister<system>() : async () {
		Cycles.add<system>(CYCLE_AMOUNT);
		let file_storage_actor = await FileStorage.FileStorage(is_prod, port);

		let principal = Principal.fromActor(file_storage_actor);
		file_storage_canister_id := Principal.toText(principal);

		let canister_child : FileStorageInfo = {
			created = Time.now();
			id = file_storage_canister_id;
			name = "file_storage";
			parent_name = ACTOR_NAME;
			status = null;
		};

		ignore Map.add(file_storage_registry, thash, file_storage_canister_id, canister_child);
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		file_storage_registry_stable_storage := Iter.toArray(Map.entries(file_storage_registry));
	};

	system func postupgrade() {
		file_storage_registry := Map.fromIter<Text, FileStorageInfo>(file_storage_registry_stable_storage.vals(), thash);

		file_storage_registry_stable_storage := [];
	};
};
