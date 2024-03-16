import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

import CreatorTypes "../actor_creator/types";
import FileStorageTypes "../actor_file_storage/types";
import UsernameRegistryTypes "../actor_username_registry/types";

actor MO = {
	type CanisterInfo = UsernameRegistryTypes.CanisterInfo;
	type FileAsset = CreatorTypes.FileAsset;
	type ProjectID = CreatorTypes.ProjectID;
	type ProjectPublic = CreatorTypes.ProjectPublic;

	type CreatorActor = CreatorTypes.CreatorActor;
	type FileStorageActor = FileStorageTypes.FileStorageActor;

	// ------------------------- Variables -------------------------
	// The Version in Production
	let VERSION : Nat = 1;
	stable var username_registry : ?Principal = null;

	// Canister Registry for Creator
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

	// Get Registry
	public query func get_registry() : async [CanisterInfo] {
		return Iter.toArray(canister_registry_creator.vals());
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared ({}) func init(username_registry_principal : Principal) : async Bool {
		if (username_registry == null) {
			username_registry := ?username_registry_principal;

			return true;
		} else {
			return false;
		};
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
