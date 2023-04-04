import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";
import Profile "canister:profile";

import HealthMetricsTypes "../types/health_metrics.types";
import SnapTypes "../service_snaps/types";
import Types "./types";

import Utils "../utils/utils";
import UtilsShared "../utils/utils";

actor class Project(project_main : Principal, is_prod : Bool) = this {
	type ErrAddSnapsToProject = Types.ErrAddSnapsToProject;
	type ErrCreateProject = Types.ErrCreateProject;
	type ErrDeleteProjects = Types.ErrDeleteProjects;
	type ErrDeleteSnapsFromProject = Types.ErrDeleteSnapsFromProject;
	type ErrUpdateProject = Types.ErrUpdateProject;
	type Project = Types.Project;
	type ProjectID = Types.ProjectID;
	type ProjectRef = Types.ProjectRef;
	type Snap = Types.Snap;
	type SnapRef = Types.SnapRef;
	type Time = Types.Time;
	type UpdateProject = Types.UpdateProject;
	type UserPrincipal = Types.UserPrincipal;

	type SnapActor = SnapTypes.SnapActor;

	type SnapPublic = SnapTypes.SnapPublic;
	type Payload = HealthMetricsTypes.Payload;

	public type ProjectPublic = {
		id : Text;
		canister_id : Text;
		created : Time;
		username : Text;
		name : Text;
		owner : Null;
		snaps : [SnapPublic];
	};

	let ACTOR_NAME : Text = "Project";
	let VERSION : Nat = 2;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	var projects : HashMap.HashMap<ProjectID, Project> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var projects_stable_storage : [(ProjectID, Project)] = [];

	// ------------------------- PROJECTS MANAGEMENT -------------------------
	public shared ({ caller }) func create_project(
		name : Text,
		snap_refs : ?[SnapRef],
		owner : UserPrincipal
	) : async Result.Result<Project, ErrCreateProject> {

		if (project_main != caller) {
			return #err(#NotAuthorized);
		};

		let project_id = ULID.toText(se.new());
		let project_canister_id = Principal.toText(Principal.fromActor(this));

		var username = "";
		switch (await Profile.get_username_public(owner)) {
			case (#ok username_) {
				username := username_;
			};
			case (#err error) {
				return #err(#UsernameNotFound);
			};
		};

		var snaps : [SnapRef] = [];
		switch (snap_refs) {
			case (?snaps_) {
				snaps := snaps_;
			};
			case (null) {};
		};

		let project : Project = {
			id = project_id;
			canister_id = project_canister_id;
			created = Time.now();
			username = username;
			owner = owner;
			name = name;
			snaps = snaps;
		};

		projects.put(project_id, project);

		return #ok(project);
	};

	public shared ({ caller }) func delete_projects(project_ids : [ProjectID]) : async Result.Result<(), ErrDeleteProjects> {
		if (project_main != caller) {
			return #err(#NotAuthorized);
		};

		for (project_id in project_ids.vals()) {
			switch (projects.get(project_id)) {
				case null {};
				case (?project) {
					projects.delete(project_id);
				};
			};
		};

		return #ok(());
	};

	public shared ({ caller }) func delete_snaps_from_project(
		snaps : [SnapRef],
		project_id : ProjectID,
		owner : UserPrincipal
	) : async Result.Result<Text, ErrDeleteSnapsFromProject> {

		let tags = [ACTOR_NAME, "delete_snaps_from_project"];

		if (project_main != caller) {
			return #err(#NotAuthorized);
		};

		// remove snaps from project
		switch (projects.get(project_id)) {
			case null {
				return #err(#ProjectNotFound);
			};
			case (?project) {
				if (project.owner != owner) {
					return #err(#NotOwner);
				};

				let updated_snaps = Utils.remove_snaps(project.snaps, snaps);

				let project_updated : Project = {
					id = project.id;
					canister_id = project.canister_id;
					created = project.created;
					username = project.username;
					owner = project.owner;
					name = project.name;
					snaps = updated_snaps;
				};

				projects.put(project_id, project_updated);

				return #ok("Snaps Deleted");
			};
		};
	};

	public shared ({ caller }) func add_snaps_to_project(
		snaps : [SnapRef],
		project_id : ProjectID,
		owner : UserPrincipal
	) : async Result.Result<Project, ErrAddSnapsToProject> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "add_snaps_to_project")];

		if (project_main != caller) {
			return #err(#NotAuthorized);
		};

		switch (projects.get(project_id)) {
			case null {
				return #err(#ProjectNotFound);
			};
			case (?project) {
				if (project.owner != owner) {
					return #err(#NotOwner);
				};

				var updated_snaps : Buffer.Buffer<SnapRef> = Buffer.fromArray(project.snaps);

				for (snap in snaps.vals()) {
					updated_snaps.add(snap);
				};

				let project_updated : Project = {
					id = project.id;
					canister_id = project.canister_id;
					created = project.created;
					username = project.username;
					owner = project.owner;
					name = project.name;
					snaps = Buffer.toArray(updated_snaps);
				};

				projects.put(project_id, project_updated);

				ignore Logger.log_event(tags, "Snaps Added To Project");

				return #ok(project);
			};
		};
	};

	public shared ({ caller }) func update_project_details(
		update_project_args : UpdateProject,
		project_ref : ProjectRef
	) : async Result.Result<Project, ErrUpdateProject> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "update_project_details")];

		if (project_main != caller) {
			return #err(#NotAuthorized);
		};

		switch (projects.get(project_ref.id)) {
			case null {
				return #err(#ProjectNotFound);
			};
			case (?project) {
				let project_updated : Project = {
					id = project.id;
					canister_id = project.canister_id;
					created = project.created;
					username = project.username;
					owner = project.owner;
					name = Option.get(update_project_args.name, project.name);
					snaps = project.snaps;
				};

				projects.put(project_ref.id, project_updated);

				ignore Logger.log_event(tags, "Project Details Updated");

				return #ok(project_updated);
			};
		};
	};

	public shared func get_projects(project_ids : [ProjectID]) : async [ProjectPublic] {
		let log_tags = [ACTOR_NAME, "get_projects"];

		var projects_list = Buffer.Buffer<ProjectPublic>(0);

		for (project_id in project_ids.vals()) {
			switch (projects.get(project_id)) {
				case null {};
				case (?project) {

					var snap_list = Buffer.Buffer<SnapPublic>(0);

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
						id = project.id;
						canister_id = project.canister_id;
						created = project.created;
						username = project.username;
						name = project.name;
						owner = null;
						snaps = Buffer.toArray(snap_list);
					};

					projects_list.add(project_public);
				};
			};
		};

		return Buffer.toArray(projects_list);
	};

	public query func get_projects_actor(project_ids : [ProjectID]) : async [Project] {
		//TODO: only allow authorized canisters to call this method

		var projects_list = Buffer.Buffer<Project>(0);

		for (project_id in project_ids.vals()) {
			switch (projects.get(project_id)) {
				case null {};
				case (?project) {
					projects_list.add(project);
				};
			};
		};

		return Buffer.toArray(projects_list);
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let tags = [
			("actor_name", ACTOR_NAME),
			("method", "health"),
			("canister_id", Principal.toText(Principal.fromActor(this))),
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
			child_canister_id = Principal.toText(Principal.fromActor(this));
			parent_canister_id = Principal.toText(project_main);
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	// ------------------------- SYSTEM METHODS -------------------------
	system func preupgrade() {
		projects_stable_storage := Iter.toArray(projects.entries());
	};

	system func postupgrade() {
		projects := HashMap.fromIter<ProjectID, Project>(
			projects_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		projects_stable_storage := [];
	};
};
