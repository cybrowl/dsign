import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import FileStorage "FileStorage";
import Logger "canister:logger";

import Types "./types";
import ICTypes "../c_types/ic";

import Health "../libs/health";

actor class FileScalingManager(is_prod : Bool, port : Text, full_threshold : Int) = this {
	type CanisterInfo = Types.CanisterInfo;
	type Status = Types.Status;
	type ErrInit = Types.ErrInit;

	type FileStorageActor = Types.FileStorageActor;
	type ICManagementActor = ICTypes.Self;

	let { thash } = Map;

	// ------------------------- Variables -------------------------
	let ACTOR_NAME : Text = "FileScalingManager";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;
	let VERSION : Nat = 5;

	stable var file_storage_canister_id : Text = "";

	// ------------------------- Storage Data -------------------------
	private var file_storage_registry = Map.new<Text, CanisterInfo>();
	stable var file_storage_registry_stable_storage : [(Text, CanisterInfo)] = [];

	// ------------------------- Actor -------------------------
	private let ic_management_actor : ICManagementActor = actor "aaaaa-aa";

	// ------------------------- File Storage Registry -------------------------
	public query func get_file_storage_registry() : async [CanisterInfo] {
		return Iter.toArray(Map.vals(file_storage_registry));
	};

	public query func get_file_storage_registry_size() : async Nat {
		return Map.size(file_storage_registry);
	};

	public query func get_current_canister_id() : async Text {
		return file_storage_canister_id;
	};

	public query func get_current_canister() : async ?CanisterInfo {
		switch (Map.get(file_storage_registry, thash, file_storage_canister_id)) {
			case (?canister) {
				return ?canister;
			};
			case _ {
				return null;
			};
		};
	};

	public shared func check_canister_is_full_public() : async () {
		let file_storage_actor = actor (file_storage_canister_id) : FileStorageActor;

		switch (await file_storage_actor.is_full()) {
			case true {
				await create_file_storage_canister();

				return ();
			};
			case false {
				return ();
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
		let file_storage_cids = Iter.toArray(Map.keys(file_storage_registry));
		let file_scaling_manager_cid : Text = Principal.toText(Principal.fromActor(this));

		ignore Logger.add_canister_id_to_registry(file_storage_cids);
		ignore Logger.add_canister_id_to_registry([file_scaling_manager_cid]);

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

	// Create File Storage Canister
	private func create_file_storage_canister<system>() : async () {
		Cycles.add<system>(CYCLE_AMOUNT);
		let file_storage_actor = await FileStorage.FileStorage(is_prod, port, full_threshold);

		let principal = Principal.fromActor(file_storage_actor);
		file_storage_canister_id := Principal.toText(principal);

		let canister_child : CanisterInfo = {
			created = Time.now();
			id = file_storage_canister_id;
			name = "file_storage";
			parent_name = ACTOR_NAME;
			status = null;
		};

		ignore Map.add(file_storage_registry, thash, file_storage_canister_id, canister_child);
	};

	// Low Cycles
	public query func cycles_low() : async Bool {
		return Health.get_cycles_low();
	};

	// Check Canister is Full
	private func check_canister_is_full() : async () {
		let file_storage_actor = actor (file_storage_canister_id) : FileStorageActor;

		switch (await file_storage_actor.is_full()) {
			case true {
				await create_file_storage_canister();

				return ();
			};
			case false {
				return ();
			};
		};
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		file_storage_registry_stable_storage := Iter.toArray(Map.entries(file_storage_registry));
	};

	system func postupgrade() {
		file_storage_registry := Map.fromIter<Text, CanisterInfo>(file_storage_registry_stable_storage.vals(), thash);

		file_storage_registry_stable_storage := [];

		ignore Timer.recurringTimer<system>(#seconds(600), check_canister_is_full);
	};
};
