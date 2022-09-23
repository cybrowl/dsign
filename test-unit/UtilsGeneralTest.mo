import Array "mo:base/Array";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Utils "../src/utils/utils";

import ActorSpec "./ActorSpec";
type Group = ActorSpec.Group;

let assertTrue = ActorSpec.assertTrue;
let assertFalse = ActorSpec.assertFalse;
let describe = ActorSpec.describe;
let it = ActorSpec.it;
let skip = ActorSpec.skip;
let pending = ActorSpec.pending;
let run = ActorSpec.run;

type SnapCanisterID = Text;
type SnapID = Text;

let success = run(
	[
		describe(
			"UtilsGeneral.get_all_ids()",
			[
				it(
					"should get all ids",
					do {
						var snap_ids_storage : HashMap.HashMap<SnapCanisterID, [SnapID]> = HashMap.HashMap(
							0,
							Text.equal,
							Text.hash
						);

						snap_ids_storage.put("xxx", ["x", "p", "y"]);
						snap_ids_storage.put("yyy", ["a", "b", "c"]);

						let response = Utils.get_all_ids(snap_ids_storage);

						assertTrue(Array.equal(response, ["a", "b", "c", "x", "p", "y"], Text.equal));
					}
				)
			]
		)
	]
);

if (success == false) {
	Debug.trap("Tests failed");
};
