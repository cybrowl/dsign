module {
	public type Payload = {
		metrics : [(Text, Int)];
		name : Text;
		child_canister_id : Text;
		parent_canister_id : Text;
	};

	// Actor Interface
	public type HealthMetricsActor = actor {
		log_event : shared (Payload) -> async ();
	};
};
