import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
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
import Logger "canister:logger";
import Profile "canister:profile";

import Types "./types";
import ProjectTypes "../service_projects/types";

actor class Snap(snap_main : Principal, project_main : Principal) = this {
	type AssetRef = Types.AssetRef;
	type CreateSnapArgs = Types.CreateSnapArgs;
	type ErrCreateSnap = Types.ErrCreateSnap;
	type ImageRef = Types.ImageRef;
	type Project = ProjectTypes.Project;
	type ProjectPublic = Types.ProjectPublic;
	type ProjectRef = ProjectTypes.ProjectRef;
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type SnapPublic = Types.SnapPublic;
	type SnapRef = Types.SnapRef;
	type UserPrincipal = Types.UserPrincipal;

	type ProjectActor = ProjectTypes.ProjectActor;

	let ACTOR_NAME : Text = "Snap";
	let VERSION : Nat = 1;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var snaps_stable_storage : [(SnapID, Snap)] = [];

	public shared ({ caller }) func create_snap(
		args : CreateSnapArgs,
		images_ref : [ImageRef],
		file_asset : AssetRef,
		owner : UserPrincipal
	) : async Result.Result<Snap, ErrCreateSnap> {

		if (snap_main != caller) {
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
			owner = owner;
			metrics = {
				likes = 0;
				views = 0;
			};
		};

		ignore Explore.save_snap(snap);

		snaps.put(snap_id, snap);

		return #ok(snap);
	};

	public shared ({ caller }) func delete_snaps(snap_ids : [SnapID]) : async () {
		if (snap_main != caller) {
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

	// NOTE: only called from Project Main
	public shared ({ caller }) func delete_project_from_snaps(
		snaps_ref : [SnapRef]
	) : async () {
		if (project_main != caller) {
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
		snaps_ref : [SnapRef],
		project_ref : ProjectRef
	) : async () {
		let tags = [ACTOR_NAME, "add_project_to_snaps"];

		if (project_main != caller) {
			ignore Logger.log_event(
				tags,
				"Unauthorized"
			);

			return ();
		};

		let project_actor = actor (project_ref.canister_id) : ProjectActor;

		switch (await project_actor.get_projects_actor([project_ref.id])) {
			case (projects) {
				let project = projects[0];

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
								project = Option.make(project);
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
		};
	};

	public query func get_all_snaps(snap_ids : [SnapID]) : async [SnapPublic] {
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
						canister_id = snap.canister_id;
						created = snap.created;
						file_asset = snap.file_asset;
						id = snap.id;
						image_cover_location = snap.image_cover_location;
						images = snap.images;
						project = project_public;
						tags = snap.tags;
						title = snap.title;
						username = snap.username;
						metrics = snap.metrics;
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
