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

import Explore "canister:explore";
import HealthMetrics "canister:health_metrics";
import Logger "canister:logger";
import Profile "canister:profile";

import HealthMetricsTypes "../types/health_metrics.types";
import ProjectTypes "../service_projects/types";
import Types "./types";

import UtilsShared "../utils/utils";

actor class Snap(snap_main : Principal, project_main : Principal, favorite_main : Principal) = this {
	type AssetRef = Types.AssetRef;
	type CreateSnapArgs = Types.CreateSnapArgs;
	type ErrCreateSnap = Types.ErrCreateSnap;
	type ErrUpdateSnap = Types.ErrUpdateSnap;
	type ImageRef = Types.ImageRef;
	type ProjectPublic = Types.ProjectPublic;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;
	type SnapRef = Types.SnapRef;
	type SnapUpdateArgs = Types.SnapUpdateArgs;
	type UserPrincipal = Types.UserPrincipal;

	type Project = ProjectTypes.Project;
	type ProjectRef = ProjectTypes.ProjectRef;
	type Payload = HealthMetricsTypes.Payload;

	type ProjectActor = ProjectTypes.ProjectActor;

	let ACTOR_NAME : Text = "Snap";
	let VERSION : Nat = 2;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var snaps_stable_storage : [(SnapID, Snap)] = [];

	stable var health_metrics_canister_id : Text = "";

	public shared ({ caller }) func create_snap(
		args : CreateSnapArgs,
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
			image_cover_location = args.image_cover_location;
			images = images_ref;
			project = null;
			tags = null;
			title = args.title;
			username = username;
			owner = Option.make(owner);
			metrics = {
				likes = 0;
				views = 0;
			};
		};

		snaps.put(snap_id, snap);

		let project_public : ?ProjectPublic = null;
		let snap_public : SnapPublic = {
			snap and {} with owner = null;
			project = project_public;
		};

		ignore Explore.save_snap(snap_public);

		return #ok(snap);
	};

	// NOTE: only called from Favorite Main
	public shared ({ caller }) func update_snap_metrics(
		snap_id : SnapID
	) : async Result.Result<SnapPublic, ErrUpdateSnap> {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "update_snap_metrics")];

		if (favorite_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return #err(#NotAuthorized(true));
		};

		switch (snaps.get(snap_id)) {
			case (null) {
				return #err(#SnapNotFound(true));
			};
			case (?snap) {

				let snap_metrics_updated = {
					likes = snap.metrics.likes + 1;
					views = snap.metrics.views;
				};

				let snap_updated = {
					snap with metrics = snap_metrics_updated;
				};

				snaps.put(snap.id, snap_updated);

				var project_public : ?ProjectPublic = null;
				switch (snap.project) {
					case (null) {};
					case (?project) {
						project_public := ?{
							project with owner = null;
						};
					};
				};

				let snap_public_updated = {
					snap with metrics = snap_metrics_updated;
					project = project_public;
					owner = null;
				};

				ignore Explore.save_snap(snap_public_updated : SnapPublic);

				return #ok(snap_public_updated);
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

		ignore Explore.delete_snaps(snap_ids);
	};

	// NOTE: only called from Project Main
	public shared ({ caller }) func delete_project_from_snaps(
		snaps_ref : [SnapRef]
	) : async () {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "delete_project_from_snaps")];

		if (project_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return ();
		};

		for (snap_ref in snaps_ref.vals()) {
			switch (snaps.get(snap_ref.id)) {
				case (null) {};
				case (?snap) {
					let update_snap : Snap = {
						canister_id = snap.canister_id;
						created = snap.created;
						file_asset = snap.file_asset;
						id = snap.id;
						image_cover_location = snap.image_cover_location;
						images = snap.images;
						project = null;
						tags = snap.tags;
						title = snap.title;
						username = snap.username;
						owner = snap.owner;
						metrics = snap.metrics;
					};

					snaps.put(snap.id, update_snap);
				};
			};
		};
	};

	// NOTE: only called from Project Main
	public shared ({ caller }) func add_project_to_snaps(
		project_ref : ProjectRef
	) : async () {
		let log_tags = [("actor_name", ACTOR_NAME), ("method", "add_project_to_snaps")];

		if (project_main != caller) {
			ignore Logger.log_event(
				log_tags,
				"Unauthorized: " # Principal.toText(caller)
			);

			return ();
		};

		let project_actor = actor (project_ref.canister_id) : ProjectActor;

		//TODO: change to only call public method to grab data
		switch (await project_actor.get_projects_actor([project_ref.id])) {
			case (projects) {
				let project = projects[0];

				for (snap_ref in project.snaps.vals()) {
					switch (snaps.get(snap_ref.id)) {
						case (null) {};
						case (?snap) {
							// update snap
							let snap_updated : Snap = {
								snap with project = Option.make(project);
							};
							snaps.put(snap.id, snap_updated);

							// update snap for explore
							let project_public : ProjectPublic = {
								project with owner = null;
							};

							let snap_public : SnapPublic = {
								snap_updated with project = Option.make(project_public);
								owner = null;
							};

							ignore Explore.save_snap(snap_public);
						};
					};
				};
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
