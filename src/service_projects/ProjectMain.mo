import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Logger "canister:logger";
import Project "Project";
import Types "./types";

actor ProjectMain {
    type CreateProjectErr = Types.CreateProjectErr;
    type Project = Types.Project;
    type ProjectCanisterID = Types.ProjectCanisterID;
    type ProjectID = Types.ProjectID;
    type SnapRef = Types.SnapRef;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "ProjectMain";
    let CYCLE_AMOUNT : Nat = 100_000_0000_000;
    let Version : Nat = 1;

    var user_canisters_ref : HashMap.HashMap<UserPrincipal, HashMap.HashMap<ProjectCanisterID, Buffer.Buffer<ProjectID>>> = HashMap.HashMap(0, Principal.equal, Principal.hash);
    stable var user_canisters_ref_storage : [var (UserPrincipal, [(ProjectCanisterID, [ProjectID])])] = [var];

    stable var project_canister_id : Text = "";

    // ------------------------- Project Management -------------------------
    public shared ({caller}) func create_project(title : Text, snaps: ?[SnapRef]) : async Result.Result<Project, CreateProjectErr> {
        let tags = [ACTOR_NAME, "create_project"];

        // get user project canister ids
        var project_canister_ids : HashMap.HashMap<ProjectCanisterID, Buffer.Buffer<ProjectID>> = HashMap.HashMap(0, Text.equal, Text.hash);
        switch (user_canisters_ref.get(caller)) {
            case (?project_canister_ids_) {
                project_canister_ids := project_canister_ids_;
            };
            case(_) {
               return #err(#UserNotFound);
            };
        };

        // get project ids from current canister id
        var project_ids = Buffer.Buffer<ProjectID>(0);
        var project_ids_found = false;
        switch (project_canister_ids.get(project_canister_id)) {
            case (?project_ids_) {
                ignore Logger.log_event(tags, debug_show("project_ids found for current empty canister"));

                project_ids := project_ids_;
                project_ids_found := true;
            };
            case(_) {
                ignore Logger.log_event(tags, debug_show("project_ids NOT found"));
            };
        };

        #err(#NotImplemented);
    };

    // delete projects

    // update project

    // move snaps from project

    // delete snaps from project

    // ------------------------- Canister Management -------------------------
    public query func version() : async Nat {
        return Version;
    };

    private func create_project_canister(project_main_principal : Principal, is_prod : Bool) : async () {
        Cycles.add(CYCLE_AMOUNT);
        let project_actor = await Project.Project(project_main_principal, is_prod);
        let principal = Principal.fromActor(project_actor);

        project_canister_id := Principal.toText(principal);
    };

    public shared (msg) func initialize_canisters(projectCanisterId : ?Text) : async ()  {
        let tags = [ACTOR_NAME, "initialize_canisters"];
        let project_main_principal = Principal.fromActor(ProjectMain);
        let is_prod = Text.equal(Principal.toText(project_main_principal), "lyswl-7iaaa-aaaag-aatya-cai");

        if (Option.isSome(projectCanisterId)) {
            project_canister_id := Option.unwrap(projectCanisterId);

            ignore Logger.log_event(tags, debug_show(("arg, project_canister_id: ", project_canister_id)));
            return ();
        };

        // create assets canister
        if (project_canister_id.size() < 1) {
            await create_project_canister(project_main_principal, is_prod);

            ignore Logger.log_event(tags, debug_show(("created, project_canister_id: ", project_canister_id)));
        } else {
            ignore Logger.log_event(tags, debug_show(("exists, project_canister_id: ", project_canister_id)));
        };
    };
};
