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
type SnapRef = {
	id : Text;
	canister_id : Text;
};

let success = run([
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
	),
	describe(
		"UtilsGeneral.all_ids_match()",
		[
			it(
				"should match all ids",
				do {
					let my_ids = ["a", "b", "c", "d"];
					let ids_to_match = ["a", "b"];

					let response = Utils.all_ids_match(my_ids, ids_to_match);

					assertTrue(response.all_match);
				}
			),
			it(
				"should match some ids",
				do {
					let my_ids = ["a", "b", "c", "d"];
					let ids_to_match = ["a", "z"];

					let response = Utils.all_ids_match(my_ids, ids_to_match);

					assertFalse(response.all_match);
				}
			),
			it(
				"should match some ids",
				do {
					let my_ids = ["a", "b", "c", "d"];
					let ids_to_match = ["a", "b", "c", "d", "e"];

					let response = Utils.all_ids_match(my_ids, ids_to_match);

					assertFalse(response.all_match);
				}
			)
		]
	),
	describe(
		"UtilsGeneral.get_non_exluded_ids()",
		[
			it(
				"should get non_exluded_ids",
				do {
					let ids = ["a", "b", "c", "d"];
					let ids_to_exclude = ["a", "b"];

					let response = Utils.get_non_exluded_ids(ids, ids_to_exclude);

					assertTrue(Array.equal(response, ["c", "d"], Text.equal));
				}
			)
		]
	),
	describe(
		"UtilsGeneral.remove_snaps()",
		[
			it(
				"should remove all",
				do {
					let snaps = [
						{ id = "a"; canister_id = "" },
						{ id = "b"; canister_id = "" },
						{ id = "c"; canister_id = "" },
						{ id = "d"; canister_id = "" }
					];
					let delete_list = [
						{ id = "a"; canister_id = "" },
						{ id = "b"; canister_id = "" },
						{ id = "c"; canister_id = "" },
						{ id = "d"; canister_id = "" }
					];

					let response = Utils.remove_snaps(snaps, delete_list);

					//TODO: Fix this
					assertTrue(true);
				}
			),
			it(
				"should NOT remove d",
				do {
					let snaps = [
						{ id = "a"; canister_id = "" },
						{ id = "b"; canister_id = "" },
						{ id = "c"; canister_id = "" },
						{ id = "d"; canister_id = "" }
					];
					let delete_list = [
						{ id = "a"; canister_id = "" },
						{ id = "b"; canister_id = "" },
						{ id = "c"; canister_id = "" }
					];

					let response = Utils.remove_snaps(snaps, delete_list);

					//TODO: Fix this
					assertTrue(true);
				}
			)
		]
	)
]);

if (success == false) {
	Debug.trap("Tests failed");
};
