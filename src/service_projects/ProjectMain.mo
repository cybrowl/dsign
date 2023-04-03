import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CanisterIdsLedger "canister:canister_ids_ledger";
import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";
import Profile "canister:profile";
import Project "Project";

import Types "./types";
import CanisterIdsLedgerTypes "../types/canidster_ids_ledger.types";
import HealthMetricsTypes "../types/health_metrics.types";
import SnapTypes "../service_snaps/types";

import Utils "../utils/utils";
import UtilsShared "../utils/utils";

actor ProjectMain {
	type ErrAddSnapsToProject = Types.ErrAddSnapsToProject;
	type ErrCreateProject = Types.ErrCreateProject;
	type ErrDeleteProjects = Types.ErrDeleteProjects;
	type ErrDeleteSnapsFromProject = Types.ErrDeleteSnapsFromProject;
	type ErrGetProjects = Types.ErrGetProjects;
	type ErrUpdateProject = Types.ErrUpdateProject;
	type ICInterface = Types.ICInterface;
	type Project = Types.Project;
	type ProjectCanisterID = Types.ProjectCanisterID;
	type ProjectID = Types.ProjectID;
	type ProjectIDStorage = Types.ProjectIDStorage;
	type ProjectPublic = Types.ProjectPublic;
	type ProjectRef = Types.ProjectRef;
	type SnapRef = Types.SnapRef;
	type UpdateProject = Types.UpdateProject;
	type UserPrincipal = Types.UserPrincipal;

	type ProjectActor = Types.ProjectActor;
	type SnapActor = SnapTypes.SnapActor;

	type CanisterInfo = CanisterIdsLedgerTypes.CanisterInfo;
	type Payload = HealthMetricsTypes.Payload;

	let ACTOR_NAME : Text = "ProjectMain";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;
	let VERSION : Nat = 2;

	private let ic : ICInterface = actor "aaaaa-aa";

	var user_canisters_ref : HashMap.HashMap<UserPrincipal, ProjectIDStorage> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var user_canisters_ref_storage : [var (UserPrincipal, [(ProjectCanisterID, [ProjectID])])] = [var];

	stable var project_canister_id : Text = "";

	// ------------------------- PROJECTS MANAGEMENT -------------------------
	public shared ({ caller }) func create_user_project_storage() : async Bool {
		let tags = [("actor_name", ACTOR_NAME), ("method", "create_user_project_storage")];

		switch (user_canisters_ref.get(caller)) {
			case (?project_canister_ids) {
				ignore Logger.log_event(tags, "exists, user_project_storage");

				return false;
			};
			case (_) {
				var project_ids_storage : ProjectIDStorage = HashMap.HashMap(
					0,
					Text.equal,
					Text.hash
				);

				user_canisters_ref.put(caller, project_ids_storage);

				ignore Logger.log_event(tags, "created, user_project_storage");

				return true;
			};
		};
	};

	public shared ({ caller }) func create_project(name : Text, snaps : ?[SnapRef]) : async Result.Result<Text, ErrCreateProject> {
		let tags = [("actor_name", ACTOR_NAME), ("method", "create_project")];

		//todo: args security checks

		var user_project_ids_storage : ProjectIDStorage = HashMap.HashMap(0, Text.equal, Text.hash);
		switch (user_canisters_ref.get(caller)) {
			case (?user_project_ids_storage_) {
				user_project_ids_storage := user_project_ids_storage_;
			};
			case (_) {
				return #err(#UserNotFound);
			};
		};

		var project_ids = Buffer.Buffer<ProjectID>(0);
		var project_ids_found = false;
		switch (user_project_ids_storage.get(project_canister_id)) {
			case (?project_ids_) {
				ignore Logger.log_event(tags, debug_show ("project_ids found"));

				project_ids := Buffer.fromArray(project_ids_);
				project_ids_found := true;
			};
			case (_) {
				ignore Logger.log_event(tags, debug_show ("project_ids NOT found"));
			};
		};

		let project_actor = actor (project_canister_id) : ProjectActor;

		// save project
		switch (await project_actor.create_project(name, snaps, caller)) {
			case (#err err) {
				return #err(#ErrorCall(debug_show (err)));
			};
			case (#ok project) {
				project_ids.add(project.id);
				user_project_ids_storage.put(project_canister_id, Buffer.toArray(project_ids));

				#ok("Created Project");
			};
		};
	};

	public shared ({ caller }) func delete_projects(project_ids_delete : [ProjectID]) : async Result.Result<Text, ErrDeleteProjects> {
		let tags = [ACTOR_NAME, "delete_projects"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_project_ids_storage) {
				let my_ids = Utils.get_all_ids(user_project_ids_storage);
				let matches = Utils.all_ids_match(my_ids, project_ids_delete);

				if (matches.all_match == false) {
					return #err(#ProjectIdsDoNotMatch);
				};

				for ((canister_id, project_ids) in user_project_ids_storage.entries()) {
					let project_actor = actor (canister_id) : ProjectActor;

					ignore project_actor.delete_projects(project_ids_delete);

					let project_ids_not_deleted = Utils.get_non_exluded_ids(
						project_ids,
						project_ids_delete
					);

					user_project_ids_storage.put(canister_id, project_ids_not_deleted);
				};

				return #ok("Deleted Projects");
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	public shared ({ caller }) func delete_snaps_from_project(
		snaps : [SnapRef],
		project_ref : ProjectRef
	) : async Result.Result<Text, ErrDeleteSnapsFromProject> {
		let tags = [ACTOR_NAME, "delete_snaps_from_project"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_project_ids_storage) {
				let my_ids = Utils.get_all_ids(user_project_ids_storage);
				let matches = Utils.all_ids_match(my_ids, [project_ref.id]);

				if (matches.all_match == false) {
					return #err(#ProjectIdsDoNotMatch);
				};

				let project_actor = actor (project_ref.canister_id) : ProjectActor;

				switch (await project_actor.delete_snaps_from_project(snaps, project_ref.id, caller)) {
					case (#err err) {
						return #err(#ErrorCall(debug_show (err)));
					};
					case (#ok _) {
						// delete project from snaps
						for (snap in snaps.vals()) {
							let snap_actor = actor (snap.canister_id) : SnapActor;
							ignore snap_actor.delete_project_from_snaps(snaps);
						};
						return #ok("Deleted Snaps From Project");
					};
				};
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	public shared ({ caller }) func add_snaps_to_project(
		snaps : [SnapRef],
		project_ref : ProjectRef
	) : async Result.Result<Text, ErrAddSnapsToProject> {
		let tags = [ACTOR_NAME, "add_snaps_to_project"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_project_ids_storage) {
				let my_ids = Utils.get_all_ids(user_project_ids_storage);
				let matches = Utils.all_ids_match(my_ids, [project_ref.id]);

				if (matches.all_match == false) {
					return #err(#ProjectIdsDoNotMatch);
				};

				let project_actor = actor (project_ref.canister_id) : ProjectActor;

				switch (await project_actor.add_snaps_to_project(snaps, project_ref.id, caller)) {
					case (#err err) {
						return #err(#ErrorCall(debug_show (err)));
					};
					case (#ok _) {

						//TODO: make this faster by filtering out unique canister ids
						for (snap in snaps.vals()) {
							let snap_actor = actor (snap.canister_id) : SnapActor;
							ignore snap_actor.add_project_to_snaps(project_ref);
						};

						return #ok("Added Snaps To Project");
					};
				};
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	public shared ({ caller }) func move_snaps_from_project(
		snaps : [SnapRef],
		project_from_ref : ProjectRef,
		project_to_ref : ProjectRef
	) : async Result.Result<Text, ErrAddSnapsToProject> {
		let tags = [ACTOR_NAME, "move_snaps_from_project"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_project_ids_storage) {
				let my_ids = Utils.get_all_ids(user_project_ids_storage);
				let from_matches = Utils.all_ids_match(my_ids, [project_from_ref.id]);
				let to_matches = Utils.all_ids_match(my_ids, [project_to_ref.id]);

				if (from_matches.all_match == false and to_matches.all_match == false) {
					return #err(#ProjectIdsDoNotMatch);
				};

				let project_actor_to = actor (project_to_ref.canister_id) : ProjectActor;
				let project_actor_from = actor (project_from_ref.canister_id) : ProjectActor;

				switch (await project_actor_to.add_snaps_to_project(snaps, project_to_ref.id, caller)) {
					case (#err err) {
						return #err(#ErrorCall(debug_show (err)));
					};
					case (#ok project) {
						//TODO: make this faster by filtering out unique canister ids
						for (snap in project.snaps.vals()) {
							let snap_actor = actor (snap.canister_id) : SnapActor;
							ignore snap_actor.add_project_to_snaps(project_to_ref);
						};
					};
				};

				switch (await project_actor_from.delete_snaps_from_project(snaps, project_from_ref.id, caller)) {
					case (#err err) {
						return #err(#ErrorCall(debug_show (err)));
					};
					case (#ok _) {
						return #ok("Moved Snaps From Project");
					};
				};

			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	public shared ({ caller }) func update_project_details(
		update_project_args : UpdateProject,
		project_ref : ProjectRef
	) : async Result.Result<Text, ErrUpdateProject> {
		let tags = [ACTOR_NAME, "update_project_details"];

		switch (user_canisters_ref.get(caller)) {
			case (?user_project_ids_storage) {
				let my_ids = Utils.get_all_ids(user_project_ids_storage);
				let matches = Utils.all_ids_match(my_ids, [project_ref.id]);

				if (matches.all_match == false) {
					return #err(#ProjectIdsDoNotMatch);
				};

				let project_actor = actor (project_ref.canister_id) : ProjectActor;

				switch (await project_actor.update_project_details(update_project_args, project_ref)) {
					case (#err err) {
						return #err(#ErrorCall(debug_show (err)));
					};
					case (#ok project) {

						//TODO: make this faster by filtering out unique canister ids
						for (snap in project.snaps.vals()) {
							let snap_actor = actor (snap.canister_id) : SnapActor;
							ignore snap_actor.add_project_to_snaps(project_ref);
						};

						return #ok("Updated Project Details");
					};
				};
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	public shared ({ caller }) func get_all_projects(username : ?Text) : async Result.Result<[ProjectPublic], ErrGetProjects> {
		let tags = [ACTOR_NAME, "get_projects"];

		var user_principal = caller;

		switch (username) {
			case (?username) {
				switch (await Profile.get_user_principal_public(username)) {
					case (#err err) {
						//TODO: log error
					};
					case (#ok principal) {
						user_principal := principal;
					};
				};
			};
			case (_) {};
		};

		switch (user_canisters_ref.get(user_principal)) {
			case (?project_canister_ids) {
				let all_projects = Buffer.Buffer<ProjectPublic>(0);

				for ((canister_id, project_ids) in project_canister_ids.entries()) {
					let project_actor = actor (canister_id) : ProjectActor;
					let projects = await project_actor.get_projects(project_ids);

					for (project in projects.vals()) {
						all_projects.add(project);
					};
				};

				if (all_projects.size() == 0) {
					return #err(#NoProjects(true));
				};

				return #ok(Buffer.toArray(all_projects));
			};
			case (_) {
				return #err(#UserNotFound(true));
			};
		};
	};

	public shared ({ caller }) func get_project(id : ProjectID, canister_id : ProjectCanisterID) : async Result.Result<ProjectPublic, Text> {
		let tags = [ACTOR_NAME, "get_project"];

		if (id.size() == 0 or id.size() > 40) {
			return #err("Project ID is invalid");
		};

		if (canister_id.size() == 0 or canister_id.size() > 40) {
			return #err("Project Canister ID is invalid");
		};

		let project_actor = actor (canister_id) : ProjectActor;
		let project = await project_actor.get_projects([id]);

		return #ok(project[0]);
	};

	public shared ({ caller }) func get_project_ids() : async Result.Result<[ProjectID], Text> {
		let tags = [ACTOR_NAME, "get_project_ids"];

		switch (user_canisters_ref.get(caller)) {
			case (?project_canister_ids) {
				let all_project_ids = Buffer.Buffer<ProjectID>(0);

				for ((canister_id, project_ids) in project_canister_ids.entries()) {
					for (project_id in project_ids.vals()) {
						all_project_ids.add(project_id);
					};
				};

				return #ok(Buffer.toArray(all_project_ids));
			};
			case (_) {
				return #err("user not found");
			};
		};
	};

	// ------------------------- CANISTER MANAGEMENT -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public shared func health() : async Payload {
		let log_payload : Payload = {
			metrics = [
				("user_can_refs", user_canisters_ref.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(ProjectMain));
			parent_canister_id = "";
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	private func create_project_canister(project_main_principal : Principal, is_prod : Bool) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let project_actor = await Project.Project(project_main_principal, is_prod);
		let principal = Principal.fromActor(project_actor);

		project_canister_id := Principal.toText(principal);

		let canister_child : CanisterInfo = {
			created = Time.now();
			id = project_canister_id;
			name = "project";
			parent_name = ACTOR_NAME;
			isProd = is_prod;
		};

		ignore CanisterIdsLedger.save_canister(canister_child);
	};

	public shared (msg) func initialize_canisters() : async Text {
		let tags = [("actor_name", ACTOR_NAME), ("method", "initialize_canisters")];

		let project_main_principal = Principal.fromActor(ProjectMain);
		let is_prod = Text.equal(
			Principal.toText(project_main_principal),
			"lyswl-7iaaa-aaaag-aatya-cai"
		);

		if (project_canister_id.size() > 1) {
			ignore Logger.log_event(tags, "exists project_canister_id: " # project_canister_id);

			return project_canister_id;
		} else {
			await create_project_canister(project_main_principal, is_prod);

			ignore Logger.log_event(tags, "created project_canister_id: " # project_canister_id);

			return project_canister_id;
		};
	};

	// UPDATE CHILD CANISTER
	public shared ({ caller }) func install_code(
		canister_id : Principal,
		arg : Blob,
		wasm_module : Blob
	) : async Text {
		let principal = Principal.toText(caller);

		if (Text.equal(principal, "isek4-vq7sa-2zqqw-xdzen-h2q5k-f47ix-5nz4o-gltx5-s75cq-63gh6-wae")) {
			await ic.install_code({
				arg = arg;
				wasm_module = wasm_module;
				mode = #upgrade;
				canister_id = canister_id;
			});

			return "success";
		};

		return "not_authorized";
	};

	// ------------------------- SYSTEM METHODS -------------------------
	system func preupgrade() {
		var anon_principal = Principal.fromText("2vxsx-fae");
		user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));

		var index = 0;
		for ((user_principal, project_ids_storage) in user_canisters_ref.entries()) {

			user_canisters_ref_storage[index] := (
				user_principal,
				Iter.toArray(project_ids_storage.entries())
			);

			index += 1;
		};
	};

	system func postupgrade() {
		var user_canisters_ref_temp : HashMap.HashMap<UserPrincipal, ProjectIDStorage> = HashMap.HashMap(
			0,
			Principal.equal,
			Principal.hash
		);

		for ((user_principal, project_ids_storage) in user_canisters_ref_storage.vals()) {
			var project_ids_storage_temp : ProjectIDStorage = HashMap.HashMap(
				0,
				Text.equal,
				Text.hash
			);

			for ((project_canister_id, project_ids) in project_ids_storage.vals()) {
				project_ids_storage_temp.put(project_canister_id, project_ids);
			};

			user_canisters_ref_temp.put(user_principal, project_ids_storage_temp);
		};

		user_canisters_ref := user_canisters_ref_temp;

		var anon_principal = Principal.fromText("2vxsx-fae");
		user_canisters_ref_storage := Array.init(user_canisters_ref.size(), (anon_principal, []));
	};
};
