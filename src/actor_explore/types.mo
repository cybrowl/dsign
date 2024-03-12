module {
	type CanisterInfo = {
		created : Int;
		id : Text;
		name : Text;
		parent_name : Text;
		isProd : Bool;
	};

	public type ExploreActor = actor {
		save_canister_info_from_creator : shared (CanisterInfo) -> async Bool;
	};

};
