module {
	public type CanisterInfo = {
		created : Int;
		id : Text;
		name : Text;
		parent_name : Text;
		isProd : Bool;
	};

	public type Tags = [(Text, Text)];
	public type Message = Text;

	public type LogEvent = {
		hostname : Text;
		logtype : Text;
		env : Text;
		message : Text;
		tags : Tags;
		time : Int;
	};

	// Actor Interface
	public type CanisterActor = actor {
		health : shared () -> async ();
		cycles_low : query () -> async Bool;
	};
};
