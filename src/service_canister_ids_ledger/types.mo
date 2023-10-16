module {
	public type CanisterIds = {
		explore : Text;
		favorite_main : Text;
		profile : Text;
		project_main : Text;
		snap_main : Text;
	};

	// Actor Interface
	public type CanisterActor = actor {
		health : shared () -> async ();
		cycles_low : query () -> async Bool;
	};

	public type Tags = [(Text, Text)];
	public type Message = Text;

	public type LoggerActor = actor {
		log_event : shared (Tags, Message) -> async ();
	};
};
