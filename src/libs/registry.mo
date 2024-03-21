import Array "mo:base/Array";

module {
	public type CanisterInfo = {
		created : Int;
		id : Text;
		name : Text;
		parent_name : Text;
		isProd : Bool;
	};

	public func get_canister_ids(
		canister_info_array : [CanisterInfo]
	) : [Text] {
		let canister_ids = Array.map<CanisterInfo, Text>(
			canister_info_array,
			func(info : CanisterInfo) : Text {
				info.id;
			}
		);

		return canister_ids;
	};
};
