import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import FileStorage "FileStorage";

import Types "./types";
import ICTypes "../c_types/ic";

import Utils "./utils";

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
	let VERSION : Nat = 1;
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
	public query func version() : async Nat {
		return VERSION;
	};

	public shared ({ caller }) func init() : async Text {
		if (file_storage_canister_id.size() > 3) {
			return file_storage_canister_id;
		} else {
			await create_file_storage_canister();

			return file_storage_canister_id;
		};
	};

	// ------------------------- Private Methods -------------------------
	private func create_file_storage_canister() : async () {
		Cycles.add(CYCLE_AMOUNT);
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

	private func update_health() : async () {
		for ((canister_id, canister) in Map.entries(file_storage_registry)) {
			let file_storage_actor = actor (canister_id) : FileStorageActor;

			switch (await file_storage_actor.get_status()) {
				case (status) {

					let status_updated : Status = {
						cycles = status.cycles;
						memory_mb = status.memory_mb;
						heap_mb = status.heap_mb;
						files_size = status.files_size;
					};

					let info_updated : FileStorageInfo = {
						canister with
						status = ?status_updated;
					};

					ignore Map.put(file_storage_registry, thash, canister_id, info_updated);
				};
			};
		};

		return ();
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
