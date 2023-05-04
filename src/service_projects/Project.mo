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

import Explore "canister:explore";
import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";
import Profile "canister:profile";

import HealthMetricsTypes "../types/health_metrics.types";
import SnapTypes "../service_snaps/types";
import Types "./types";

import Utils "../utils/utils";
import UtilsShared "../utils/utils";

actor class Project(project_main : Principal, snap_main : Principal, favorite_main : Principal, is_prod : Bool) = this {
	type ErrAddSnapsToProject = Types.ErrAddSnapsToProject;
	type ErrCreateProject = Types.ErrCreateProject;
	type ErrDeleteProjects = Types.ErrDeleteProjects;
	type ErrDeleteSnapsFromProject = Types.ErrDeleteSnapsFromProject;
	type ErrUpdateProject = Types.ErrUpdateProject;
	type Project = Types.Project;
	type ProjectUpdateAction = Types.ProjectUpdateAction;
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
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};

	let ACTOR_NAME : Text = "Project";
	let VERSION : Nat = 2;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	var projects : HashMap.HashMap<ProjectID, Project> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var projects_stable_storage : [(ProjectID, Project)] = [];

	// ------------------------- Projects Methods -------------------------
	public shared ({ caller }) func create_project(
		name : Text,
		snap_refs : ?[SnapRef],
		owner : UserPrincipal
	) : async Result.Result<Project, ErrCreateProject> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "create_project")];

		if (project_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

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
			metrics = {
				likes = 0;
				views = 0;
			};
		};

		projects.put(project_id, project);

		return #ok(project);
	};

	public shared ({ caller }) func delete_projects(project_ids : [ProjectID]) : async Result.Result<(), ErrDeleteProjects> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "delete_projects")];

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

		ignore Explore.delete_projects(project_ids);

		return #ok(());
	};

	public shared ({ caller }) func delete_snaps_from_project(
		snaps : [SnapRef],
		project_id : ProjectID,
		owner : UserPrincipal
	) : async Result.Result<Text, ErrDeleteSnapsFromProject> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "delete_snaps_from_project")];

		if (project_main == caller or snap_main == caller) {
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
						project with
						snaps = updated_snaps;
					};

					projects.put(project_id, project_updated);

					ignore Explore.save_project(project_updated);

					return #ok("Snaps Deleted");
				};
			};
		} else {
			return #err(#NotAuthorized);
		};
	};

	public shared ({ caller }) func add_snaps_to_project(
		snaps : [SnapRef],
		project_id : ProjectID,
		owner : UserPrincipal
	) : async Result.Result<Project, ErrAddSnapsToProject> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "add_snaps_to_project")];

		if (project_main == caller or snap_main == caller) {

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
						project with
						snaps = Buffer.toArray(updated_snaps);
					};

					projects.put(project_id, project_updated);

					ignore Explore.save_project(project_updated);

					ignore Logger.log_event(log_tags, "Snaps Added To Project");

					return #ok(project);
				};
			};
		} else {
			return #err(#NotAuthorized);
		};
	};

	public shared ({ caller }) func update_project_details(
		update_project_args : UpdateProject,
		project_ref : ProjectRef
	) : async Result.Result<Project, ErrUpdateProject> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "update_project_details")];

		if (project_main != caller) {
			return #err(#NotAuthorized(true));
		};

		switch (projects.get(project_ref.id)) {
			case null {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				let project_updated : Project = {
					project with
					name = Option.get(update_project_args.name, project.name);
				};

				projects.put(project_ref.id, project_updated);

				ignore Explore.save_project(project_updated);

				ignore Logger.log_event(log_tags, "Project Details Updated");

				return #ok(project_updated);
			};
		};
	};

	// NOTE: only called from Favorite Main
	public shared ({ caller }) func update_project_metrics(
		project_id : ProjectID,
		action_type : ProjectUpdateAction
	) : async Result.Result<(), ErrUpdateProject> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "update_snap_metrics")];

		if (favorite_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return #err(#NotAuthorized(true));
		};

		switch (projects.get(project_id)) {
			case (null) {
				return #err(#ProjectNotFound(true));
			};
			case (?project) {
				var project_metrics_updated = {
					likes = 0;
					views = 0;
				};

				switch (action_type) {
					case (#LikeAdd) {
						project_metrics_updated := {
							likes = project.metrics.likes + 1;
							views = project.metrics.views;
						};
					};
					case (#LikeRemove) {};
				};

				let project_updated = {
					project with metrics = project_metrics_updated;
				};

				projects.put(project.id, project_updated);

				return #ok(());
			};
		};
	};

	public query func owner_check(id : ProjectID, owner : Principal) : async Bool {
		switch (projects.get(id)) {
			case (null) {
				return false;
			};
			case (?project) {
				if (project.owner == owner) {
					return true;
				} else {
					return false;
				};
			};
		};
	};

	public shared func get_projects(project_ids : [ProjectID]) : async [ProjectPublic] {
		let log_tags = [ACTOR_NAME, "get_projects"];

		//TODO: CanisterIdsLedger.canister_exists to stop DDOS

		var projects_list = Buffer.Buffer<ProjectPublic>(0);

		for (project_id in project_ids.vals()) {
			switch (projects.get(project_id)) {
				case null {};
				case (?project) {

					var snap_list = Buffer.Buffer<SnapPublic>(0);

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
						id = project.id;
						canister_id = project.canister_id;
						created = project.created;
						username = project.username;
						name = project.name;
						owner = null;
						snaps = Buffer.toArray(snap_list);
						metrics = project.metrics;
					};

					projects_list.add(project_public);
				};
			};
		};

		return Buffer.toArray(projects_list);
	};

	public query func get_projects_actor(project_ids : [ProjectID]) : async [Project] {
		//TODO: CanisterIdsLedger.canister_exists to stop DDOS

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

	// ------------------------- Canister Management -------------------------
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

	// ------------------------- System Methods -------------------------
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
