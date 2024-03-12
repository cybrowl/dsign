import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import CreatorTypes "../actor_creator/types";
import UsernameRegistryTypes "../actor_username_registry/types";

actor class Explore(username_registry : Principal) = this {
	type ProjectID = CreatorTypes.ProjectID;
	type ProjectPublic = CreatorTypes.ProjectPublic;
	type CanisterInfo = UsernameRegistryTypes.CanisterInfo;

	// ------------------------- Variables -------------------------
	let VERSION = 1;

	// ------------------------- Storage Data -------------------------
	var projects : HashMap.HashMap<ProjectID, ProjectPublic> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var projects_stable_storage : [(ProjectID, ProjectPublic)] = [];

	// Canister Registry for Creator
	var canister_registry_creator : HashMap.HashMap<Principal, CanisterInfo> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);

	// Save Canister Info from Creator
	public shared ({ caller }) func save_canister_info_from_creator() : async Result.Result<Text, Text> {
		if (Principal.equal(caller, username_registry)) {
			return #ok("save info");
		};

		return #ok("");
	};

	// Save Project
	public shared ({ caller }) func save_project() : async Result.Result<Text, Text> {
		let is_authorized : Bool = switch (canister_registry_creator.get(caller)) {
			case (null) { false };
			case (?info) { true };
		};

		return #ok("");
	};

	// Delete Projects
	public shared ({ caller }) func delete_projects(project_ids : [ProjectID]) : async () {
		let is_authorized : Bool = switch (canister_registry_creator.get(caller)) {
			case (null) { false };
			case (?info) { true };
		};

		if (is_authorized) {
			for (project_id in project_ids.vals()) {
				switch (projects.get(project_id)) {
					case null {};
					case (?project) {
						projects.delete(project_id);
					};
				};
			};
		};
	};

	public query func get_all_projects() : async [ProjectPublic] {
		return Iter.toArray(projects.vals());
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
