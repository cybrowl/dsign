import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

import Logger "canister:logger";

import CreatorTypes "../actor_creator/types";
import FileStorageTypes "../actor_file_storage/types";
import UsernameRegistryTypes "../actor_username_registry/types";

import Health "../libs/health";

actor MO = {
	type CanisterInfo = UsernameRegistryTypes.CanisterInfo;
	type FileAsset = CreatorTypes.FileAsset;
	type ProjectID = CreatorTypes.ProjectID;
	type ProjectPublic = CreatorTypes.ProjectPublic;

	type CreatorActor = CreatorTypes.CreatorActor;
	type FileStorageActor = FileStorageTypes.FileStorageActor;

	// ------------------------- Variables -------------------------
	let ACTOR_NAME : Text = "M-O";
	let VERSION : Nat = 4; // The Version in Production
	stable var username_registry : ?Principal = null;

	// ------------------------- Storage Data -------------------------
	var canister_registry_creator : HashMap.HashMap<Principal, CanisterInfo> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var canister_registry_creator_stable_storage : [(Principal, CanisterInfo)] = [];

	// ------------------------- M-O -------------------------
	// Save Canister Info from Creator
	public shared ({ caller }) func save_canister_info_from_creator(info : CanisterInfo) : async Bool {
		switch (username_registry) {
			case (null) {
				return false;
			};
			case (?username_registry_) {
				if (Principal.equal(caller, username_registry_)) {
					canister_registry_creator.put(Principal.fromText(info.id), info);

					return true;
				} else {
					return false;
				};
			};
		};
	};

	// Delete Files
	public shared ({ caller }) func delete_files(file_assets : [FileAsset]) : async Bool {
		let is_authorized : Bool = switch (canister_registry_creator.get(caller)) {
			case (null) { false };
			case (?info) { true };
		};

		if (is_authorized) {
			for (file_asset in file_assets.vals()) {
				let file_storage_actor : FileStorageActor = actor (file_asset.canister_id);
				ignore file_storage_actor.delete_file(file_asset.id);
			};

			return true;
		} else {
			return false;
		};
	};

	// Update File Ownership
	public shared ({ caller }) func update_file_ownership(file : FileAsset, owner : Principal) : async Bool {
		let is_authorized : Bool = switch (canister_registry_creator.get(caller)) {
			case (null) { false };
			case (?info) { true };
		};

		if (is_authorized) {
			let file_storage_actor : FileStorageActor = actor (file.canister_id);

			let file_ownership_update = await file_storage_actor.update_file_ownership(file, owner);

			switch (file_ownership_update) {
				case (true) {
					return true;
				};
				case (false) {
					return false;
				};
			};
		} else {
			return false;
		};
	};

	// ------------------------- Canister Management -------------------------
	// Version
	public query func version() : async Nat {
		return VERSION;
	};

	// Init
	public shared func init(username_registry_principal : Principal) : async Bool {

		let mo_cid : Text = Principal.toText(Principal.fromActor(MO));
		ignore Logger.add_canister_id_to_registry([mo_cid]);

		if (username_registry == null) {
			username_registry := ?username_registry_principal;

			return true;
		} else {
			return false;
		};
	};

	// Get Registry
	public query func get_registry() : async [CanisterInfo] {
		return Iter.toArray(canister_registry_creator.vals());
	};

	// Health
	public shared func health() : async () {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("version", Int.toText(VERSION)),
			("canister_registry_creator_size", Int.toText(canister_registry_creator.size())),
			("cycles_balance", Int.toText(Health.get_cycles_balance())),
			("memory_in_mb", Int.toText(Health.get_memory_in_mb())),
			("heap_in_mb", Int.toText(Health.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);

		return ();
	};

	// Low Cycles
	public query func cycles_low() : async Bool {
		return Health.get_cycles_low();
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		canister_registry_creator_stable_storage := Iter.toArray(canister_registry_creator.entries());
	};

	system func postupgrade() {
		canister_registry_creator := HashMap.fromIter<Principal, CanisterInfo>(
			canister_registry_creator_stable_storage.vals(),
			0,
			Principal.equal,
			Principal.hash
		);
		canister_registry_creator_stable_storage := [];
	};
};
