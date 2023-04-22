import { Buffer; toArray } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";

import HealthMetricsTypes "../types/health_metrics.types";
import Types "./types";

import UtilsShared "../utils/utils";

actor class Favorite(favorite_main : Principal) = this {
	type ErrDeleteFavorite = Types.ErrDeleteFavorite;
	type ErrGetFavorite = Types.ErrGetFavorite;
	type ErrSaveFavorite = Types.ErrSaveFavorite;
	type ProjectID = Types.ProjectID;
	type ProjectRef = Types.ProjectRef;
	type ProjectPublic = Types.ProjectPublic;

	type ProjectActor = Types.ProjectActor;

	type Payload = HealthMetricsTypes.Payload;

	let ACTOR_NAME : Text = "Favorite";
	let VERSION : Nat = 1;

	var projects : HashMap.HashMap<ProjectID, ProjectRef> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var projects_stable_storage : [(ProjectID, ProjectRef)] = [];

	public shared ({ caller }) func save_project(project : ProjectRef) : async Result.Result<ProjectRef, ErrSaveFavorite> {
		if (favorite_main != caller) {
			return #err(#NotAuthorized(true));
		};

		projects.put(project.id, project);

		return #ok(project);
	};

	public shared ({ caller }) func delete_project(project_id : ProjectID) : async Result.Result<ProjectRef, ErrDeleteFavorite> {
		if (favorite_main != caller) {
			return #err(#NotAuthorized(true));
		};

		switch (projects.get(project_id)) {
			case null {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				projects.delete(project_id);

				return #ok(project);
			};
		};
	};

	public shared ({ caller }) func get_all_projects(project_ids : [ProjectID]) : async Result.Result<[ProjectPublic], ErrGetFavorite> {
		if (favorite_main != caller) {
			return #err(#NotAuthorized(true));
		};

		var projects_ref = Buffer<ProjectRef>(0);
		var projects_public = Buffer<ProjectPublic>(0);

		for (project_id in project_ids.vals()) {
			switch (projects.get(project_id)) {
				case null {};
				case (?project) {
					projects_ref.add(project);
				};
			};
		};

		let group_project_refs = UtilsShared.group_project_refs_by_canister_id(projects_ref);

		for (project_ref in group_project_refs.vals()) {
			let project_actor = actor (project_ref.canister_id) : ProjectActor;

			switch (await project_actor.get_projects(project_ref.ids)) {
				case (projects) {

					for (project in projects.vals()) {
						projects_public.add(project);
					};
				};
			};
		};

		return #ok(toArray(projects_public));
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("canister_id", Principal.toText(Principal.fromActor(this))),
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
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(this));
			parent_canister_id = Principal.toText(favorite_main);
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		projects_stable_storage := Iter.toArray(projects.entries());

	};

	system func postupgrade() {
		projects := HashMap.fromIter<ProjectID, ProjectRef>(
			projects_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		projects_stable_storage := [];
	};
};
