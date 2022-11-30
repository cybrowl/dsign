import { Buffer } "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";

actor Explore = {
	type Snap = Types.Snap;
	type SnapID = Types.SnapID;
	type SnapCanisterId = Types.SnapCanisterId;

	var snaps : HashMap.HashMap<SnapID, Snap> = HashMap.HashMap(0, Text.equal, Text.hash);
	stable var snaps_stable_storage : [(SnapID, Snap)] = [];

	var snaps_authorized_can_ids : HashMap.HashMap<SnapCanisterId, SnapCanisterId> = HashMap.HashMap(0, Text.equal, Text.hash);

	public query func ping() : async Text {
		return "pong";
	};

	public shared func save_snap(snap : Snap) : async Text {
		snaps.put(snap.id, snap);

		return "meow";
	};

	public query func get_all_snaps() : async [Snap] {
		return Iter.toArray(snaps.vals());
	};

	public query func length() : async Nat {
		return snaps.size();
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
