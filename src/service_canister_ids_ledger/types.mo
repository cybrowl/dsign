import HealthMetricsTypes "../types/health_metrics.types";

module {
	type Payload = HealthMetricsTypes.Payload;

	public type CanisterIds = {
		explore : Text;
		favorite_main : Text;
		profile : Text;
		project_main : Text;
		snap_main : Text;
	};

	// Actor Interface
	public type CanisterActor = actor {
		health : shared () -> async Payload;
	};

};
