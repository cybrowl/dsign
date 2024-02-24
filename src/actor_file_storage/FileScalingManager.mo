import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import FileStorage "FileStorage";

import Types "./types";
import TypesIC "../c_types/ic";

import Utils "./utils";

actor class FileScalingManager(is_prod : Bool, port : Text) = this {
	type CanisterInfo = Types.CanisterInfo;
	type Status = Types.Status;

	type FileStorageActor = Types.FileStorageActor;
	type ManagementActor = TypesIC.Self;

	let { thash } = Map;

	// ------------------------- Variables -------------------------
	let ACTOR_NAME : Text = "FileScalingManager";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;
	let VERSION : Nat = 1;
	stable var file_storage_canister_id : Text = "";

	// ------------------------- Storage Data -------------------------
	private var canister_records = Map.new<Text, CanisterInfo>();
	stable var canister_records_stable_storage : [(Text, CanisterInfo)] = [];

	// ------------------------- Actor -------------------------
	private let management_actor : ManagementActor = actor "aaaaa-aa";

	// ------------------------- Canister Records -------------------------
	public query func get_file_storage_canister_id() : async Text {
		return file_storage_canister_id;
	};

	public query func get_canister_records() : async [CanisterInfo] {
		return Iter.toArray(Map.vals(canister_records));
	};

	public query func get_current_canister() : async ?CanisterInfo {
		switch (Map.get(canister_records, thash, file_storage_canister_id)) {
			case (?canister) {
				return ?canister;
			};
			case _ {
				return null;
			};
		};
	};

	public shared ({ caller }) func init() : async Text {
		if (file_storage_canister_id == "") {
			await create_file_storage_canister();

			let settings = {
				controllers = ?[caller, Principal.fromActor(this)];
				freezing_threshold = ?2_592_000;
				memory_allocation = ?0;
				compute_allocation = ?0;
			};

			ignore management_actor.update_settings({
				canister_id = Principal.fromText(file_storage_canister_id);
				settings = settings;
			});

			return "Created: " # file_storage_canister_id;
		};

		return "Exists: " # file_storage_canister_id;
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	// ------------------------- Private Methods -------------------------
	private func create_file_storage_canister() : async () {
		Cycles.add(CYCLE_AMOUNT);
		let file_storage_actor = await FileStorage.FileStorage(is_prod, port);

		let principal = Principal.fromActor(file_storage_actor);
		file_storage_canister_id := Principal.toText(principal);

		let canister_child : CanisterInfo = {
			created = Time.now();
			id = file_storage_canister_id;
			name = "file_storage";
			parent_name = ACTOR_NAME;
			status = null;
		};

		ignore Map.put(canister_records, thash, file_storage_canister_id, canister_child);
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
		let canister_entries = Map.entries(canister_records);

		for ((canister_id, canister) in canister_entries) {
			let file_storage_actor = actor (canister_id) : FileStorageActor;

			switch (await file_storage_actor.get_status()) {
				case (health) {

					let health_updated : Status = {
						cycles = health.cycles;
						memory_mb = health.memory_mb;
						heap_mb = health.heap_mb;
						assets_size = health.assets_size;
					};

					let canister_record_updated : CanisterInfo = {
						canister with
						status = ?health_updated;
					};

					ignore Map.put(canister_records, thash, canister_id, canister_record_updated);
				};
			};
		};

		return ();
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		canister_records_stable_storage := Iter.toArray(Map.entries(canister_records));
	};

	system func postupgrade() {
		canister_records := Map.fromIter<Text, CanisterInfo>(canister_records_stable_storage.vals(), thash);

		ignore Timer.recurringTimer(#seconds(600), check_canister_is_full);
		ignore Timer.recurringTimer(#seconds(600), update_health);

		canister_records_stable_storage := [];
	};
};
