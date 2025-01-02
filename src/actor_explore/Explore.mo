import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import Logger "canister:logger";

import CreatorTypes "../actor_creator/types";
import UsernameRegistryTypes "../actor_username_registry/types";

import Health "../libs/health";

actor Explore {
	type ProjectID = CreatorTypes.ProjectID;
	type ProjectPublic = CreatorTypes.ProjectPublic;
	type CanisterInfo = UsernameRegistryTypes.CanisterInfo;

	type CreatorActor = CreatorTypes.CreatorActor;

	// ------------------------- Variables -------------------------
	let ACTOR_NAME : Text = "Explore";
	let VERSION = 4; // The Version in Production
	stable var username_registry : ?Principal = null;

	// ------------------------- Storage Data -------------------------
	// Projects
	var projects : HashMap.HashMap<ProjectID, ProjectPublic> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var projects_stable_storage : [(ProjectID, ProjectPublic)] = [];

	// Canister Registry for Creator
	var canister_registry_creator : HashMap.HashMap<Principal, CanisterInfo> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var canister_registry_creator_stable_storage : [(Principal, CanisterInfo)] = [];

	// ------------------------- Explore -------------------------
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

	// Save Project
	public shared ({ caller }) func save_project(project : ProjectPublic) : async Bool {
		let is_authorized : Bool = switch (canister_registry_creator.get(caller)) {
			case (null) { false };
			case (?_info) { true };
		};

		if (is_authorized) {
			projects.put(project.id, project);

			return true;
		} else {
			return false;
		};
	};

	// Update Project
	public shared ({ caller }) func update_project(project_id : ProjectID, canister_id : Text) : async Bool {
		let is_authorized : Bool = switch (canister_registry_creator.get(caller)) {
			case (null) { false };
			case (?_info) { true };
		};

		if (is_authorized) {
			let creator_actor : CreatorActor = actor (canister_id);

			switch (await creator_actor.get_project(project_id)) {
				case (#err _err) {
					return false;
				};
				case (#ok project) {
					projects.put(project.id, project);

					return true;
				};
			};
		} else {
			return false;
		};
	};

	// Delete Projects
	public shared ({ caller }) func delete_projects(project_ids : [ProjectID]) : async Bool {
		let is_authorized : Bool = switch (canister_registry_creator.get(caller)) {
			case (null) { false };
			case (?_info) { true };
		};

		if (is_authorized) {
			for (project_id in project_ids.vals()) {
				switch (projects.get(project_id)) {
					case null {};
					case (?_project) {
						projects.delete(project_id);
					};
				};
			};

			return true;
		} else {
			return false;
		};
	};

	// Get Projects
	public query func get_all_projects() : async [ProjectPublic] {
		return Iter.toArray(projects.vals());
	};

	// ------------------------- Canister Management -------------------------
	// Version
	public query func version() : async Nat {
		return VERSION;
	};

	// Init
	public shared func init(username_registry_principal : Principal) : async Bool {
		let explore_cid : Text = Principal.toText(Principal.fromActor(Explore));
		ignore Logger.add_canister_id_to_registry([explore_cid]);

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
			("projects_size", Int.toText(projects.size())),
			("cycles_balance", Int.toText(Health.get_cycles_balance())),
			("memory_in_mb", Int.toText(Health.get_memory_in_mb())),
			("heap_in_mb", Int.toText(Health.get_heap_in_mb()))
		];

		ignore Logger.log_event(
			tags,
			"health"
		);
	};

	// Low Cycles
	public query func cycles_low() : async Bool {
		return Health.get_cycles_low();
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		projects_stable_storage := Iter.toArray(projects.entries());

		canister_registry_creator_stable_storage := Iter.toArray(canister_registry_creator.entries());
	};

	system func postupgrade() {
		projects := HashMap.fromIter<ProjectID, ProjectPublic>(
			projects_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		projects_stable_storage := [];

		canister_registry_creator := HashMap.fromIter<Principal, CanisterInfo>(
			canister_registry_creator_stable_storage.vals(),
			0,
			Principal.equal,
			Principal.hash
		);
		canister_registry_creator_stable_storage := [];
	};
};
