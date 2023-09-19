import Arr "mo:array/Array";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Prim "mo:⛔";
import Text "mo:base/Text";

module {
	public type IDStorage = HashMap.HashMap<Text, [Text]>;
	public type Matches = {
		all_match : Bool;
		ids_not_found : [Text];
	};
	public type SnapRef = {
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

	public func get_all_ids(user_ids_storage : IDStorage) : [Text] {
		var all_ids = Buffer.Buffer<Text>(0);

		for ((canister_id, ids) in user_ids_storage.entries()) {
			for (id in ids.vals()) {
				all_ids.add(id);
			};
		};

		return Buffer.toArray(all_ids);
	};

	public func all_ids_match(my_ids : [Text], ids_to_match : [Text]) : Matches {
		var result = true;
		var ids_not_found = Buffer.Buffer<Text>(0);

		for (id in ids_to_match.vals()) {
			let found = Arr.contains(my_ids, id, Text.equal);

			if (found == false) {
				result := false;
				ids_not_found.add(id);
			};
		};

		let matches = {
			all_match = result;
			ids_not_found = Buffer.toArray(ids_not_found);
		};

		return matches;
	};

	func findIndex<X>(arr : [X], predicate : X -> Bool) : ?Nat {
		let len = Array.size(arr);
		for (i in Iter.range(0, len - 1)) {
			if (predicate(arr[i])) {
				return ?i;
			};
		};
		null;
	};

	public func group_project_refs_by_canister_id(projectRefs : Buffer.Buffer<ProjectRef>) : [MatchingIdsResult] {
		var project_refs_arr = Buffer.toArray<ProjectRef>(projectRefs);
		var grouped_results = Buffer.Buffer<MatchingIdsResult>(0);

		for (project_ref in project_refs_arr.vals()) {
			let existing_result = Array.find<MatchingIdsResult>(
				Buffer.toArray(grouped_results),
				func(result) {
					return result.canister_id == project_ref.canister_id;
				}
			);

			switch (existing_result) {
				case (null) {
					// No existing result for the current canister_id, create a new one
					let result : MatchingIdsResult = {
						canister_id = project_ref.canister_id;
						ids = [project_ref.id];
					};

					grouped_results.add(result);
				};
				case (?result) {
					let result_ids : [Text] = Array.tabulate<Text>(
						result.ids.size() + 1,
						func(i : Nat) : Text {
							if (i < result.ids.size()) {
								result.ids[i];
							} else {
								project_ref.id;
							};
						}
					);

					let result_updated : MatchingIdsResult = {
						canister_id = result.canister_id;
						ids = result_ids;
					};

					let index = findIndex<MatchingIdsResult>(
						Buffer.toArray(grouped_results),
						func(res) {
							return res.canister_id == result.canister_id;
						}
					);

					switch (index) {
						case (?idx) {
							grouped_results.put(idx, result_updated);
						};
						case (null) {};
					};
				};
			};
		};

		return Buffer.toArray(grouped_results);
	};

	public func some(my_ids : [Text], ids_to_match : [Text]) : Bool {
		for (id in ids_to_match.vals()) {
			let found = Arr.contains(my_ids, id, Text.equal);

			if (found == true) {
				return true;
			};
		};

		return false;
	};

	public func get_non_exluded_ids(ids : [Text], ids_to_exclude : [Text]) : [Text] {
		let non_exluded_ids = Array.filter(
			ids,
			func(id : Text) : Bool {
				let found = Arr.contains(ids_to_exclude, id, Text.equal);

				if (found) {
					return false;
				} else {
					return true;
				};
			}
		);

		return non_exluded_ids;
	};

	public func remove_snaps(snaps : [SnapRef], delete_list : [SnapRef]) : [SnapRef] {
		let result = Array.filter(
			snaps,
			func(snap : SnapRef) : Bool {
				let found = Arr.contains(
					delete_list,
					snap,
					func(a : SnapRef, b : SnapRef) : Bool {
						return Text.equal(a.id, b.id);
					}
				);

				if (found) {
					return false;
				} else {
					return true;
				};
			}
		);

		return result;
	};

	public func get_memory_in_mb() : Int {
		let rts_memory_size : Nat = Prim.rts_memory_size();
		let mem_size : Float = Float.fromInt(rts_memory_size);
		let memory_in_megabytes = Float.toInt(Float.abs(mem_size / 1_048_576));

		return memory_in_megabytes;
	};

	public func get_heap_in_mb() : Int {
		let rts_heap_size : Nat = Prim.rts_heap_size();
		let heap_size : Float = Float.fromInt(rts_heap_size);
		let heap_in_megabytes = Float.toInt(Float.abs(heap_size / 1_048_576));

		return heap_in_megabytes;
	};

	public func get_cycles_balance() : Int {
		return ExperimentalCycles.balance();
	};

	public func get_cycles_low() : Bool {
		if (ExperimentalCycles.balance() < 2_000_000_000_000) {
			return true;
		} else {
			return false;
		};
	};

	public func is_full() : Bool {
		let MAX_SIZE_THRESHOLD_MB : Float = 2000;

		let rts_memory_size : Nat = Prim.rts_memory_size();
		let mem_size : Float = Float.fromInt(rts_memory_size);
		let memory_in_megabytes = Float.abs(mem_size * 0.000001);

		if (memory_in_megabytes > MAX_SIZE_THRESHOLD_MB) {
			return true;
		} else {
			return false;
		};
	};

	public func get_canister_id_from_storage(storage : IDStorage, target_id : Text) : ?Text {

		for ((canisterId, ids) in storage.entries()) {
			if (Arr.contains(ids, target_id, Text.equal)) {
				return ?canisterId;
			};
		};

		return null;
	};

	public func check_user_ownership(storage : IDStorage, ids : [Text]) : Bool {
		let myIds = get_all_ids(storage);
		let matches = all_ids_match(myIds, ids);

		return matches.all_match;
	};

};
