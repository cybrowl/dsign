actor class Project(controller: Principal, is_prod: Bool) = {
    let Version : Nat = 1;

    public query func version() : async Nat {
        return Version;
    };
};