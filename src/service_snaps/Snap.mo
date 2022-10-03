import Array "mo:base/Array";
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
import ProjectTypes "../service_projects/types";

actor class Snap(controller : Principal, project_main_principal : Principal) = this {
	type AssetRef = Types.AssetRef;
	type CreateSnapArgs = Types.CreateSnapArgs;
	type ImageRef = Types.ImageRef;
	type Project = ProjectTypes.Project;
	type ProjectActor = ProjectTypes.ProjectActor;
	type Snap = Types.Snap;
	type SnapPublic = Types.SnapPublic;
	type SnapID = Types.SnapID;
	type SnapRef = Types.SnapRef;
	type UserPrincipal = Types.UserPrincipal;

	let ACTOR_NAME : Text = "Snap";
	let VERSION : Nat = 1;

	private let rr = XorShift.toReader(XorShift.XorShift64(null));
	private let se = Source.Source(rr, 0);

	var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var snaps_stable_storage : [(SnapID, Snap)] = [];

	//TODO: only allow snap_main to accesss write methods

	public shared({ caller }) func create_snap(
		args : CreateSnapArgs,
		images_ref : [ImageRef],
		file_asset : AssetRef,
		owner : UserPrincipal
	) : async Result.Result<Snap, Text> {

		if (controller != caller) {
			return #err("Unauthorized");
		};

		let snap_id = ULID.toText(se.new());
		let snap_canister_id = Principal.toText(Principal.fromActor(this));

		var username = "";
		switch (await Username.get_username_actor(owner)) {
			case (#ok username_) {
				username := username_;
			};
			case (#err error) {
				return #err("Username Not Found");
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

		snaps.put(snap_id, snap);

		return #ok(snap);
	};

	public shared({ caller }) func delete_snaps(snapIds : [SnapID]) : async () {
		if (controller != caller) {
			return ();
		};

		for (snap_id in snapIds.vals()) {
			switch (snaps.get(snap_id)) {
				case null {};
				case (?snap) {
					snaps.delete(snap_id);
				};
			};
		};
	};

	public shared({ caller }) func update_snap_project(
		snaps_ref : [SnapRef],
		project : ?Project
	) : async Result.Result<Text, Text> {
		if (project_main_principal != caller) {
			return #err("Unauthorized");
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
						project = project;
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

		#ok("Updated Snap Project");
	};

	public shared({ caller }) func delete_project_from_snaps(
		snaps_ref : [SnapRef]
	) : async Result.Result<Text, Text> {
		if (project_main_principal != caller) {
			return #err("Unauthorized");
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

		#ok("Deleted Project From Snaps");
	};

	public query func get_all_snaps(snapIds : [SnapID]) : async [SnapPublic] {
		var snaps_list = Buffer.Buffer<SnapPublic>(0);

		for (snap_id in snapIds.vals()) {
			switch (snaps.get(snap_id)) {
				case null {};
				case (?snap) {

					let snap_public : SnapPublic = {
						canister_id = snap.canister_id;
						created = snap.created;
						file_asset = snap.file_asset;
						id = snap.id;
						image_cover_location = snap.image_cover_location;
						images = snap.images;
						project = snap.project;
						tags = snap.tags;
						title = snap.title;
						username = snap.username;
						metrics = snap.metrics;
					};

					snaps_list.add(snap_public);
				};
			};
		};

		return snaps_list.toArray();
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
