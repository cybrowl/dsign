import Array "mo:base/Array";
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
import Explore "canister:explore";

import HealthMetricsTypes "../types/health_metrics.types";
import ProjectTypes "../service_projects/types";
import Types "./types";

import UtilsShared "../utils/utils";

actor class Snap(snap_main : Principal, project_main : Principal, favorite_main : Principal) = this {
	type AssetRef = Types.AssetRef;
	type CreateSnapArgs = Types.CreateSnapArgs;
	type EditSnapArgs = Types.EditSnapArgs;
	type ErrCreateSnap = Types.ErrCreateSnap;
	type ErrDeleteDesignFile = Types.ErrDeleteDesignFile;
	type ErrEditSnap = Types.ErrEditSnap;
	type ImageID = Types.ImageID;
	type ImageRef = Types.ImageRef;
	type ProjectPublic = Types.ProjectPublic;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;
	type SnapRef = Types.SnapRef;
	type UserPrincipal = Types.UserPrincipal;

	type Project = ProjectTypes.Project;
	type ProjectRef = ProjectTypes.ProjectRef;
	type Payload = HealthMetricsTypes.Payload;

	type ProjectActor = ProjectTypes.ProjectActor;

	let ACTOR_NAME : Text = "Snap";
	let VERSION : Nat = 3;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var snaps_stable_storage : [(SnapID, Snap)] = [];

	stable var health_metrics_canister_id : Text = "";

	public shared ({ caller }) func create_snap(
		snap_info : CreateSnapArgs,
		images_ref : [ImageRef],
		file_asset : AssetRef,
		owner : UserPrincipal
	) : async Result.Result<Snap, ErrCreateSnap> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "create_snap")];

		if (snap_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return #err(#Unauthorized);
		};

		let snap_id = ULID.toText(se.new());
		let snap_canister_id = Principal.toText(Principal.fromActor(this));

		var username = "";
		switch (await Profile.get_username_public(owner)) {
			case (#ok username_) {
				username := username_;
			};
			case (#err error) {
				return #err(#UsernameNotFound);
			};
		};

		let snap : Snap = {
			canister_id = snap_canister_id;
			created = Time.now();
			file_asset = file_asset;
			id = snap_id;
			image_cover_location = snap_info.image_cover_location;
			images = images_ref;
			project = null;
			project_ref = ?{
				id = snap_info.project.id;
				canister_id = snap_info.project.canister_id;
			};
			tags = null;
			title = snap_info.title;
			username = username;
			owner = Option.make(owner);
			metrics = {
				likes = 0;
				views = 0;
			};
		};

		snaps.put(snap_id, snap);

		return #ok(snap);
	};

	public shared ({ caller }) func edit_snap(
		snap_info : EditSnapArgs,
		images_ref : ?[ImageRef],
		file_asset : AssetRef,
		owner : UserPrincipal
	) : async Result.Result<Snap, ErrEditSnap> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "edit_snap")];

		if (snap_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return #err(#Unauthorized);
		};

		switch (snaps.get(snap_info.id)) {
			case (null) {
				return #err(#SnapNotFound);
			};
			case (?snap) {
				let name = Option.get(snap_info.title, snap.title);
				let image_cover_location = Option.get(snap_info.image_cover_location, snap.image_cover_location);
				let images_refs = Option.get(images_ref, []);
				let images = Array.flatten([snap.images, images_refs]);

				var design_file = snap.file_asset;
				if (file_asset.id != "") {
					design_file := file_asset;
				};

				let snap_updated = {
					snap with images = images;
					file_asset = design_file;
					image_cover_location = image_cover_location;
					title = name;
				};

				snaps.put(snap.id, snap_updated);

				switch (snap.project_ref) {
					case (null) {};
					case (?project_ref) {
						ignore Explore.update_project(project_ref);

					};
				};

				return #ok(snap_updated);
			};
		};
	};

	public shared ({ caller }) func delete_snaps(snap_ids : [SnapID]) : async () {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "delete_snaps")];

		if (snap_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return ();
		};

		for (snap_id in snap_ids.vals()) {
			switch (snaps.get(snap_id)) {
				case null {};
				case (?snap) {
					snaps.delete(snap_id);
				};
			};
		};
	};

	public shared ({ caller }) func delete_images(snap_id : SnapID, image_refs : [ImageRef]) : async () {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "delete_images")];

		if (snap_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return ();
		};

		switch (snaps.get(snap_id)) {
			case null {};
			case (?snap) {
				let updated_images = Array.filter(
					snap.images,
					func(snap_image_ref : ImageRef) : Bool {
						Array.find(
							image_refs,
							func(image_ref : ImageRef) : Bool {
								snap_image_ref.id == image_ref.id;
							}
						) == null;
					}
				);

				snaps.put(snap_id, { snap with images = updated_images });

				switch (snap.project_ref) {
					case (null) {};
					case (?project_ref) {
						ignore Explore.update_project(project_ref);

					};
				};
			};
		};
	};

	public shared ({ caller }) func delete_design_file(
		snap_id : SnapID
	) : async Result.Result<Snap, ErrDeleteDesignFile> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "delete_design_file")];

		if (snap_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return #err(#Unauthorized);
		};

		switch (snaps.get(snap_id)) {
			case (null) {
				return #err(#SnapNotFound);
			};
			case (?snap) {
				let file_asset = {
					canister_id = "";
					id = "";
					file_name = "";
					url = "";
					is_public = false;
				};

				let snap_updated : Snap = {
					snap with file_asset;
				};

				snaps.put(snap.id, snap_updated);

				switch (snap.project_ref) {
					case (null) {};
					case (?project_ref) {
						ignore Explore.update_project(project_ref);
					};
				};

				return #ok(snap_updated);
			};
		};
	};

	public query func get_all_snaps(snap_ids : [SnapID]) : async [SnapPublic] {
		//TODO: CanisterIdsLedger.canister_exists to stop DDOS

		var snaps_list = Buffer.Buffer<SnapPublic>(0);

		for (snap_id in snap_ids.vals()) {
			switch (snaps.get(snap_id)) {
				case null {};
				case (?snap) {

					let project_public = label project : ?ProjectPublic {
						switch (snap.project) {
							case (null) {
								null;
							};
							case (?project) {
								var project_public : ProjectPublic = {
									id = project.id;
									canister_id = project.canister_id;
									created = project.created;
									username = project.username;
									name = project.name;
									snaps = [];
								};

								?project_public;

							};
						};
					};

					let snap_public : SnapPublic = {
						snap and {} with owner = null;
						project = project_public;
					};

					snaps_list.add(snap_public);
				};
			};
		};

		return Buffer.toArray(snaps_list);
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
			("snaps_size", Int.toText(snaps.size())),
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
				("snaps_num", snaps.size()),
				("cycles_balance", UtilsShared.get_cycles_balance()),
				("memory_in_mb", UtilsShared.get_memory_in_mb()),
				("heap_in_mb", UtilsShared.get_heap_in_mb())
			];
			name = ACTOR_NAME;
			child_canister_id = Principal.toText(Principal.fromActor(this));
			parent_canister_id = Principal.toText(snap_main);
		};

		ignore HealthMetrics.log_event(log_payload);

		return log_payload;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		snaps_stable_storage := Iter.toArray(snaps.entries());
	};

	system func postupgrade() {
		snaps := HashMap.fromIter<SnapID, Snap>(
			snaps_stable_storage.vals(),
			0,
			Text.equal,
			Text.hash
		);
		snaps_stable_storage := [];
	};
};
