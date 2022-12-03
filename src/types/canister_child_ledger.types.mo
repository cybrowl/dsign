module {
	public type Time = Int;

	public type CanisterChild = {
		created : Time;
		id : Text;
		name : Text;
		parent_name : Text;
		isProd : Bool;
	};
};
