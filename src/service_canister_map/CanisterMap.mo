import Types "./types";

actor class CanisterMap(args: Types.InitArgs) = {
    private let profile_ : Text = args.profile;
    private let snap_main_ : Text = args.snap_main;
    private let username_ : Text = args.username;

    public query func get_canister_id(name: Text) : async Text {
        switch(name){
            case("profile") {
                return profile_;
            };
            case("snap_main") {
                return snap_main_;
            };
            case("username") {
                return username_;
            };
            case(_) {
                return "not found";
            };
        };
    };
};