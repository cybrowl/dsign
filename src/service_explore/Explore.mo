import { Buffer; toArray } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CanisterIdsLedger "canister:canister_ids_ledger";
import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";

import HealthMetricsTypes "../types/health_metrics.types";
import SnapTypes "../service_snaps/types";
import Types "./types";

import UtilsShared "../utils/utils";

actor Explore = {
	type Project = Types.Project;
	type ProjectActor = Types.ProjectActor;
	type ProjectID = Types.ProjectID;
	type ProjectPublic = Types.ProjectPublic;
	type ProjectRef = Types.ProjectRef;
	type SnapPublic = SnapTypes.SnapPublic;
	type Time = Int;

	type SnapActor = SnapTypes.SnapActor;
	type Payload = HealthMetricsTypes.Payload;

	var projects : HashMap.HashMap<ProjectID, ProjectPublic> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var projects_stable_storage : [(ProjectID, ProjectPublic)] = [];

	let ACTOR_NAME : Text = "Explore";
	let VERSION : Nat = 3;

	public shared ({ caller }) func save_project(project : Project) : async Text {
		let authorized = await CanisterIdsLedger.canister_exists(Principal.toText(caller));
		let description : Text = Option.get(project.description, "");

		// covert project to public project to save
		var snap_list = Buffer<SnapPublic>(0);

		//TODO: there is an optimization here
		for (snap in project.snaps.vals()) {
			let snap_actor = actor (snap.canister_id) : SnapActor;

			switch (await snap_actor.get_all_snaps([snap.id])) {
				case (snap_) {
					if (snap_.size() > 0) {
						snap_list.add(snap_[0]);
					};
				};
			};
		};

		let project_public : ProjectPublic = {
			project and {} with owner = null;
			description = description;
			snaps = toArray(snap_list);
		};

		projects.put(project.id, project_public);

		return "Saved project";
	};

	public shared func update_project(project_ref : ProjectRef) : async Text {
		let project_actor = actor (project_ref.canister_id) : ProjectActor;

		switch (await project_actor.get_projects([project_ref.id])) {
			case (projects_) {
				let project = projects_[0];
				var snap_list = Buffer<SnapPublic>(0);

				//TODO: there is an optimization here
				for (snap in project.snaps.vals()) {
					let snap_actor = actor (snap.canister_id) : SnapActor;

					switch (await snap_actor.get_all_snaps([snap.id])) {
						case (snap_) {
							if (snap_.size() > 0) {
								snap_list.add(snap_[0]);
							};
						};
					};
				};

				let project_public : ProjectPublic = {
					project and {} with owner = null;
					snaps = toArray(snap_list);
				};

				projects.put(project.id, project_public);

				return "Updated project";
			};
		};

	};

	public shared ({ caller }) func delete_projects(project_ids : [ProjectID]) : async () {
		let authorized = await CanisterIdsLedger.canister_exists(Principal.toText(caller));

		for (project_id in project_ids.vals()) {
			switch (projects.get(project_id)) {
				case null {};
				case (?project) {
					projects.delete(project_id);
				};
			};
		};
	};

	public query func get_all_projects() : async [ProjectPublic] {
		return Iter.toArray(projects.vals());
	};

	public query func length() : async Nat {
		return projects.size();
	};

	// ------------------------- Canister Management -------------------------
	public shared func health() : async Payload {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("projects_size", Int.toText(projects.size())),
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
				("projects_num", projects.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(Explore));
			parent_canister_id = "";
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	public query func version() : async Nat {
		return VERSION;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		projects_stable_storage := Iter.toArray(projects.entries());
	};

	system func postupgrade() {
		projects := HashMap.fromIter<ProjectID, ProjectPublic>(
			projects_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		projects_stable_storage := [];
	};
};
