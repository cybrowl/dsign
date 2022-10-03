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

import Logger "canister:logger";
import Project "Project";

import Types "./types";
import SnapTypes "../service_snaps/types";
import Utils "../utils/utils";

actor ProjectMain {
	type CreateProjectErr = Types.CreateProjectErr;
	type DeleteProjectsErr = Types.DeleteProjectsErr;
	type DeleteSnapsFromProjectErr = Types.DeleteSnapsFromProjectErr;
	type GetProjectsErr = Types.GetProjectsErr;
	type Project = Types.Project;
	type ProjectActor = Types.ProjectActor;
	type ProjectCanisterID = Types.ProjectCanisterID;
	type ProjectID = Types.ProjectID;
	type ProjectIDStorage = Types.ProjectIDStorage;
	type ProjectRef = Types.ProjectRef;
	type SnapActor = SnapTypes.SnapActor;
	type SnapRef = Types.SnapRef;
	type UserPrincipal = Types.UserPrincipal;

	let ACTOR_NAME : Text = "ProjectMain";
	let CYCLE_AMOUNT : Nat = 100_000_0000_000;
	let VERSION : Nat = 1;

	var user_canisters_ref : HashMap.HashMap<UserPrincipal, ProjectIDStorage> = HashMap.HashMap(
		0,
		Principal.equal,
		Principal.hash
	);
	stable var user_canisters_ref_storage : [var (UserPrincipal, [(ProjectCanisterID, [ProjectID])])] = [var];

	stable var project_canister_id : Text = "";

	// ------------------------- Project Management -------------------------
	public shared({ caller }) func create_user_project_storage() : async Bool {
		let tags = [ACTOR_NAME, "create_user_project_storage"];

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

	public shared({ caller }) func create_project(name : Text, snaps : ?[SnapRef]) : async Result.Result<Text, CreateProjectErr> {
		let tags = [ACTOR_NAME, "create_project"];

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
				user_project_ids_storage.put(project_canister_id, project_ids.toArray());

				// add project to snaps
				for (snap in project.snaps.vals()) {
					let snap_ref = {
						id = snap.id;
						canister_id = snap.canister_id;
					};

					let snap_actor = actor (snap.canister_id) : SnapActor;
					ignore snap_actor.update_snap_project([snap_ref], project);
				};

				#ok("Created Project");
			};
		};
	};

	public shared({ caller }) func delete_projects(project_ids_delete : [ProjectID]) : async Result.Result<Text, DeleteProjectsErr> {
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

	public shared({ caller }) func delete_snaps_from_project(
		snaps : [SnapRef],
		project_ref : ProjectRef
	) : async Result.Result<Text, DeleteSnapsFromProjectErr> {
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
						// todo: the front end needs to handle removing the snaps
						return #ok("Deleted Snaps From Project");
					};
				};
			};
			case (_) {
				#err(#UserNotFound);
			};
		};
	};

	// move snaps to project

	// update project

	public shared({ caller }) func get_projects() : async Result.Result<[Project], GetProjectsErr> {
		let tags = [ACTOR_NAME, "get_projects"];

		switch (user_canisters_ref.get(caller)) {
			case (?project_canister_ids) {
				let all_projects = Buffer.Buffer<Project>(0);

				for ((canister_id, project_ids) in project_canister_ids.entries()) {
					let project_actor = actor (canister_id) : ProjectActor;
					let projects = await project_actor.get_projects(project_ids);

					for (project in projects.vals()) {
						all_projects.add(project);
					};
				};

				return #ok(all_projects.toArray());
			};
			case (_) {
				return #err(#UserNotFound);
			};
		};
	};

	public shared({ caller }) func get_project_ids() : async Result.Result<[ProjectID], Text> {
		let tags = [ACTOR_NAME, "get_project_ids"];

		switch (user_canisters_ref.get(caller)) {
			case (?project_canister_ids) {
				let all_project_ids = Buffer.Buffer<ProjectID>(0);

				for ((canister_id, project_ids) in project_canister_ids.entries()) {
					for (project_id in project_ids.vals()) {
						all_project_ids.add(project_id);
					};
				};

				return #ok(all_project_ids.toArray());
			};
			case (_) {
				return #err("user not found");
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	private func create_project_canister(project_main_principal : Principal, is_prod : Bool) : async () {
		Cycles.add(CYCLE_AMOUNT);
		let project_actor = await Project.Project(project_main_principal, is_prod);
		let principal = Principal.fromActor(project_actor);

		project_canister_id := Principal.toText(principal);
	};

	public shared(msg) func initialize_canisters(projectCanisterId : ?Text) : async Text {
		let tags = [ACTOR_NAME, "initialize_canisters"];
		let project_main_principal = Principal.fromActor(ProjectMain);
		let is_prod = Text.equal(
			Principal.toText(project_main_principal),
			"lyswl-7iaaa-aaaag-aatya-cai"
		);

		if (project_canister_id.size() > 1) {
			ignore Logger.log_event(
				tags,
				debug_show (("project_canister_id already set: ", project_canister_id))
			);

			return project_canister_id;
		};

		switch (projectCanisterId) {
			case (null) {
				ignore Logger.log_event(tags, debug_show ("no arg, creating project_canister_id"));

				await create_project_canister(project_main_principal, is_prod);
			};
			case (?projectCanisterId_) {
				project_canister_id := projectCanisterId_;

				ignore Logger.log_event(
					tags,
					debug_show (("arg, project_canister_id: ", project_canister_id))
				);
			};
		};

		return project_canister_id;
	};

	// ------------------------- System Methods -------------------------
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
