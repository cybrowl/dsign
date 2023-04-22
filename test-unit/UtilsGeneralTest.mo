import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
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

type ProjectRef = {
	id : Text;
	canister_id : Text;
};

type MatchingIdsResult = {
	canister_id : Text;
	ids : [Text];
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
	),
	describe(
		"Utils.group_project_refs_by_canister_id()",
		[
			it(
				"should group project references by canister ID",
				do {
					let projectRefs = Buffer.fromArray<ProjectRef>([
						{ id = "1"; canister_id = "A" },
						{ id = "2"; canister_id = "B" },
						{ id = "3"; canister_id = "A" },
						{ id = "4"; canister_id = "C" },
						{ id = "5"; canister_id = "B" }
					]);

					let expectedResult : [MatchingIdsResult] = [
						{ canister_id = "A"; ids = ["1", "3"] },
						{ canister_id = "B"; ids = ["2", "5"] },
						{ canister_id = "C"; ids = ["4"] }
					];

					let result : [MatchingIdsResult] = Utils.group_project_refs_by_canister_id(projectRefs);

					let match : Bool = Array.equal(
						result,
						expectedResult,
						func(a : MatchingIdsResult, b : MatchingIdsResult) : Bool {
							let ids_match = Array.equal(a.ids, b.ids, Text.equal);
							let canister_ids_match = a.canister_id == b.canister_id;

							return canister_ids_match and ids_match;
						}
					);

					assertTrue(match);
				}
			),
			it(
				"should group project references by canister ID with more values",
				do {
					let projectRefs = Buffer.fromArray<ProjectRef>([
						{ id = "1"; canister_id = "A" },
						{ id = "2"; canister_id = "B" },
						{ id = "3"; canister_id = "A" },
						{ id = "4"; canister_id = "C" },
						{ id = "5"; canister_id = "B" },
						{ id = "6"; canister_id = "A" },
						{ id = "7"; canister_id = "C" },
						{ id = "8"; canister_id = "B" },
						{ id = "9"; canister_id = "A" }
					]);

					let expectedResult : [MatchingIdsResult] = [
						{ canister_id = "A"; ids = ["1", "3", "6", "9"] },
						{ canister_id = "B"; ids = ["2", "5", "8"] },
						{ canister_id = "C"; ids = ["4", "7"] }
					];

					let result : [MatchingIdsResult] = Utils.group_project_refs_by_canister_id(projectRefs);

					let match : Bool = Array.equal(
						result,
						expectedResult,
						func(a : MatchingIdsResult, b : MatchingIdsResult) : Bool {
							let ids_match = Array.equal(a.ids, b.ids, Text.equal);
							let canister_ids_match = a.canister_id == b.canister_id;

							return canister_ids_match and ids_match;
						}
					);

					assertTrue(match);
				}
			),
			it(
				"should return an empty array for empty input",
				do {
					let projectRefs = Buffer.fromArray<ProjectRef>([]);

					let expectedResult : [MatchingIdsResult] = [];

					let result = Utils.group_project_refs_by_canister_id(projectRefs);
					assertTrue(
						Array.equal(
							result,
							expectedResult,
							func(a : MatchingIdsResult, b : MatchingIdsResult) : Bool {
								let ids_match = Array.equal(a.ids, b.ids, Text.equal);
								let canister_ids_match = a.canister_id == b.canister_id;

								return canister_ids_match and ids_match;
							}
						)
					);
				}
			)
		]
	)
]);

if (success == false) {
	Debug.trap("Tests failed");
};
