import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import Types "./types";

module {
	type FavoriteID = Types.FavoriteID;
	type FileAsset = Types.FileAsset;
	type FileAssetID = Types.FileAssetID;
	type Project = Types.Project;
	type ProjectID = Types.ProjectID;
	type ProjectPublic = Types.ProjectPublic;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;
	type Topic = Types.Topic;

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

	public func favorites_to_public(
		favorite_ids : [FavoriteID],
		favorites : HashMap.HashMap<FavoriteID, ProjectPublic>
	) : [ProjectPublic] {
		return Array.mapFilter<FavoriteID, ProjectPublic>(
			favorite_ids,
			func(id : FavoriteID) : ?ProjectPublic {
				switch (favorites.get(id)) {
					case (null) {
						return null;
					};
					case (?project) {
						return ?project;
					};
				};
			}
		);
	};

	public func get_file_assets_from_project(
		project : Project,
		snaps : HashMap.HashMap<SnapID, Snap>
	) : [FileAsset] {
		let snap_file_assets : [[FileAsset]] = Array.map<SnapID, [FileAsset]>(
			project.snaps,
			func(snap_id : SnapID) : [FileAsset] {
				switch (snaps.get(snap_id)) {
					case (null) { return [] };
					case (?snap) {
						let design_file : [FileAsset] = switch (snap.design_file) {
							case (null) { [] };
							case (?file_asset) { [file_asset] };
						};

						let images : [FileAsset] = snap.images;

						return Array.flatten<FileAsset>([design_file, images]);
					};
				};
			}
		);

		return Array.flatten<FileAsset>(snap_file_assets);
	};

	public func get_file_assets_from_topic(
		topic : Topic
	) : [FileAsset] {
		switch (topic.design_file) {
			case (null) {
				return [];
			};
			case (?file_asset) {
				return [file_asset];
			};
		};
	};

	public func get_file_assets_from_snap(
		snap : Snap
	) : [FileAsset] {
		let design_file : [FileAsset] = switch (snap.design_file) {
			case (null) { [] };
			case (?file_asset) { [file_asset] };
		};

		let images : [FileAsset] = snap.images;

		return Array.flatten<FileAsset>([design_file, images]);
	};

	public func filter_out_project_id(
		projects : [ProjectID],
		id_to_remove : ProjectID
	) : [ProjectID] {
		let projects_buffer : Buffer.Buffer<ProjectID> = Buffer.fromArray(projects);

		// Filter out the project ID to be deleted
		projects_buffer.filterEntries(
			func(idx : Nat, proj_id : ProjectID) : Bool {
				return proj_id != id_to_remove;
			}
		);

		// Convert the buffer back to an array and return
		return Buffer.toArray(projects_buffer);
	};
};
