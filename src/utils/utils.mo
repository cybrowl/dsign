import Arr "mo:array/Array";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
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

	public func get_all_ids(user_ids_storage : IDStorage) : [Text] {
		var all_ids = Buffer.Buffer<Text>(0);

		for ((canister_id, ids) in user_ids_storage.entries()) {
			for (id in ids.vals()) {
				all_ids.add(id);
			};
		};

		return all_ids.toArray();
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
			ids_not_found = ids_not_found.toArray();
		};

		return matches;
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

};
