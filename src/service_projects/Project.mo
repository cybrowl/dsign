import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import Username "canister:username";

import Types "./types";

actor class Project(controller : Principal, is_prod : Bool) = this {
	type CreateProjectErr = Types.CreateProjectErr;
	type DeleteProjectsErr = Types.DeleteProjectsErr;
	type DeleteSnapsFromProjectErr = Types.DeleteSnapsFromProjectErr;
	type Project = Types.Project;
	type ProjectID = Types.ProjectID;
	type SnapRef = Types.SnapRef;
	type UserPrincipal = Types.UserPrincipal;

	let ACTOR_NAME : Text = "Project";
	let VERSION : Nat = 1;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	var projects : HashMap.HashMap<ProjectID, Project> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var projects_stable_storage : [(ProjectID, Project)] = [];

	public shared ({ caller }) func create_project(
		name : Text,
		snap_refs : ?[SnapRef],
		owner : UserPrincipal
	) : async Result.Result<Project, CreateProjectErr> {

		if (controller != caller) {
			return #err(#NotAuthorized);
		};

		let project_id = ULID.toText(se.new());
		let project_canister_id = Principal.toText(Principal.fromActor(this));

		var username = "";
		switch (await Username.get_username_actor(owner)) {
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

	public shared ({ caller }) func delete_projects(projectIds : [ProjectID]) : async Result.Result<(), DeleteProjectsErr> {
		if (controller != caller) {
			return #err(#NotAuthorized);
		};

		for (project_id in projectIds.vals()) {
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
	) : async Result.Result<Text, DeleteSnapsFromProjectErr> {

		let tags = [ACTOR_NAME, "delete_snaps_from_project"];

		if (controller != caller) {
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

				let snaps_kept = Buffer.Buffer<SnapRef>(0);

				for (snap in snaps.vals()) {
					for (project_snap in project.snaps.vals()) {
						if (snap.id != project_snap.id) {
							snaps_kept.add(project_snap);
						};
					};
				};

				// todo: remove project from snaps that are removed from project

				let project_updated : Project = {
					id = project.id;
					canister_id = project.canister_id;
					created = project.created;
					username = project.username;
					owner = project.owner;
					name = project.name;
					snaps = snaps_kept.toArray();
				};

				projects.put(project_id, project_updated);

				return #ok("Snaps Deleted");
			};
		};
	};

	public query func get_projects(projectIds : [ProjectID]) : async [Project] {
		var projects_list = Buffer.Buffer<Project>(0);

		for (project_id in projectIds.vals()) {
			switch (projects.get(project_id)) {
				case null {};
				case (?project) {
					projects_list.add(project);
				};
			};
		};

		return projects_list.toArray();
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
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
