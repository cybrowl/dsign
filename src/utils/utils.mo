import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Debug "mo:base/Debug";
import Text "mo:base/Text";

module {
	public type IDStorage = HashMap.HashMap<Text, [Text]>;

	public func get_all_ids(user_ids_storage : IDStorage) : [Text] {
		var all_ids = Buffer.Buffer<Text>(0);

		for ((canister_id, ids) in user_ids_storage.entries()) {
			for (id in ids.vals()) {
				all_ids.add(id);
			};
		};

		return all_ids.toArray();
	};

};
