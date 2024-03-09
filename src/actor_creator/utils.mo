import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import Types "./types";

module {
	type Project = Types.Project;
	type ProjectID = Types.ProjectID;
	type ProjectPublic = Types.ProjectPublic;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;

	public func project_to_public(
		project : Project,
		snaps : HashMap.HashMap<SnapID, Snap>,
		caller : Principal
	) : ProjectPublic {
		let snaps_public : [SnapPublic] = Array.mapFilter<SnapID, SnapPublic>(
			project.snaps,
			func(id : SnapID) : ?SnapPublic {
				switch (snaps.get(id)) {
					case (null) {
						return null;
					};
					case (?snap) {
						let snap_public : SnapPublic = {
							snap with
							owner = null;
							is_owner = Principal.equal(caller, snap.owner);
						};

						return ?snap_public;
					};
				};
			}
		);

		let project_public : ProjectPublic = {
			project with
			is_owner = Principal.equal(caller, project.owner);
			owner = null;
			snaps = snaps_public;
		};

		return project_public;
	};

	public func projects_to_public(
		project_ids : [ProjectID],
		projects : HashMap.HashMap<ProjectID, Project>,
		snaps : HashMap.HashMap<SnapID, Snap>,
		caller : Principal
	) : [ProjectPublic] {
		return Array.mapFilter<ProjectID, ProjectPublic>(
			project_ids,
			func(id : ProjectID) : ?ProjectPublic {
				switch (projects.get(id)) {
					case (null) { return null };
					case (?project) {
						let snaps_public : [SnapPublic] = Array.mapFilter<SnapID, SnapPublic>(
							project.snaps,
							func(snap_id : SnapID) : ?SnapPublic {
								switch (snaps.get(snap_id)) {
									case (null) { return null };
									case (?snap) {
										let snap_public : SnapPublic = {
											snap with
											owner = null;
											is_owner = Principal.equal(caller, snap.owner);
										};

										return ?snap_public;
									};
								};
							}
						);

						let project_public : ProjectPublic = {
							project with is_owner = Principal.equal(caller, project.owner);
							owner = null;
							snaps = snaps_public;
						};

						return ?project_public;
					};
				};
			}
		);
	};
};
