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
    type DeleteProjectsErr = Types.DeleteProjectsErr;
    type Project = Types.Project;
    type ProjectActor = Types.ProjectActor;
    type ProjectCanisterID = Types.ProjectCanisterID;
    type ProjectID = Types.ProjectID;
    type SnapRef = Types.SnapRef;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "ProjectMain";
    let CYCLE_AMOUNT : Nat = 100_000_0000_000;
    let VERSION : Nat = 1;

    var user_canisters_ref : HashMap.HashMap<UserPrincipal, HashMap.HashMap<ProjectCanisterID, Buffer.Buffer<ProjectID>>> = HashMap.HashMap(0, Principal.equal, Principal.hash);
    stable var user_canisters_ref_storage : [var (UserPrincipal, [(ProjectCanisterID, [ProjectID])])] = [var];

    stable var project_canister_id : Text = "";

    // ------------------------- Project Management -------------------------
    public shared ({caller}) func create_user_project_storage() : async Bool {
        let tags = [ACTOR_NAME, "create_user_project_storage"];

        switch (user_canisters_ref.get(caller)) {
            case (?project_canister_ids) {
                ignore Logger.log_event(tags, "exists, user_project_storage");

                return false;
            };
            case (_) {
                var empty_project_canister_id_storage : HashMap.HashMap<ProjectCanisterID, Buffer.Buffer<ProjectID>> = HashMap.HashMap(0, Text.equal, Text.hash);

                user_canisters_ref.put(caller, empty_project_canister_id_storage);

                ignore Logger.log_event(tags, "created, user_project_storage");

                return true;
            };
        };
    };

    public shared ({caller}) func create_project(name : Text, snaps: ?[SnapRef]) : async Result.Result<Project, CreateProjectErr> {
        let tags = [ACTOR_NAME, "create_project"];

        //todo: args security checks

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

        let project_actor = actor (project_canister_id) : ProjectActor;

        // save project
        switch(await project_actor.create_project(name, snaps, caller)) {
            case(#err err) {
                return #err(#ErrorCall(debug_show(err)));
            };
            case(#ok project) {
                project_ids.add(project.id);
                if (project_ids_found == false) {
                    project_canister_ids.put(project_canister_id, project_ids);
                };

                //TODO: remove owner from project
                #ok(project);
            };
        };
    };

    public shared ({caller}) func delete_projects(projectIds: [ProjectID]) : async Result.Result<Text, DeleteProjectsErr> {
        let tags = [ACTOR_NAME, "delete_projects"];

        switch (user_canisters_ref.get(caller)) {
            case (?project_canister_ids) {
                for ((canister_id, project_ids) in project_canister_ids.entries()) {
                    let project_actor = actor (canister_id) : ProjectActor;

                    ignore project_actor.delete_projects(projectIds);
                };

                return #ok("delete_projects");
            };
            case (_) {
                #err(#UserNotFound)
            };
        };
    };

    // delete snaps from project

    // move snaps from project

    // update project

    // get all projects
    public shared ({caller}) func get_projects() : async Result.Result<[Project], Text> {
        let tags = [ACTOR_NAME, "get_projects"];

        switch (user_canisters_ref.get(caller)) {
            case (?project_canister_ids) {
                let all_projects = Buffer.Buffer<Project>(0);

                for ((canister_id, project_ids) in project_canister_ids.entries()) {
                    let project_actor = actor (canister_id) : ProjectActor;
                    let projects = await project_actor.get_projects(project_ids.toArray());

                    for (project in projects.vals()) {
                        all_projects.add(project);
                    };
                };

                return #ok(all_projects.toArray());
            };
            case (_) {
                return #err("user not found");
            };
        };
    };

    // ------------------------- Canister Management -------------------------
    public query func version() : async Nat {
        return VERSION;
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
