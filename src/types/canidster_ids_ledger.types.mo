module {
	public type Time = Int;

	public type CanisterInfo = {
		created : Time;
		id : Text;
		name : Text;
		parent_name : Text;
		isProd : Bool;
	};
};
