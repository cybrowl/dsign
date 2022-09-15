import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import Username "canister:username";

import Types "./types";

actor class Project(controller: Principal, is_prod: Bool) = this {
    type Project = Types.Project;
    type ProjectID = Types.ProjectID;
    type SnapRef = Types.SnapRef;
    type UserPrincipal = Types.UserPrincipal;

    let Version : Nat = 1;

    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);

    var projects : HashMap.HashMap<ProjectID, Project> = HashMap.HashMap(0, Text.equal, Text.hash);
    stable var projects_stable_storage : [(ProjectID, Project)] = [];

    public shared ({caller}) func create_project(
        name: Text,
        snap_refs: ?[SnapRef],
        owner: UserPrincipal) : async Result.Result<Project, Text> {

        if (controller != caller) {
            return #err("Unauthorized");
        };

        let project_id =  ULID.toText(se.new());
        let project_canister_id =  Principal.toText(Principal.fromActor(this));

        var username = "";
        switch(await Username.get_username_actor(owner)) {
            case(#ok username_) {
                username:= username_;
            };
            case(#err error) {
                return #err("Username Not Found");
            };
        };

        var snaps : [SnapRef] = [];
        switch(snap_refs) {
            case(?snaps_) {
                snaps := snaps_;
            };
            case(null) {
            };
        };

        let project : Project = {
            id = project_id;
            canister_id = project_canister_id;
            created = Time.now();
            username = username;
            owner = owner;
            name = name;
            snaps = snaps;
        };

        projects.put(project_id, project);

        return #ok(project);
    };

    public shared ({caller}) func delete_projects(projectIds: [ProjectID]) : async () {
        if (controller != caller) {
            return ();
        };

        for (project_id in projectIds.vals()){
            switch (projects.get(project_id)){
                case null {};
                case (?project) {
                    projects.delete(project_id);
                };
            }
        };
    };

    // ------------------------- Canister Management -------------------------
    public query func version() : async Nat {
        return Version;
    };
};