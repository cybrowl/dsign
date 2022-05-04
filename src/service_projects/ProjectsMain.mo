import Cycles "mo:base/ExperimentalCycles";
import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Debug "mo:base/Debug";

import Project "Project";
import Logger "canister:logger";
import Types "./types";

actor ProjectsMain {
    type CanisterProjectID = Types.CanisterProjectID;
    type ProjectID = Types.ProjectID;
    type UserPrincipal = Types.UserPrincipal;

    let ACTOR_NAME : Text = "ProjectsMain";
    let cycleAmount : Nat = 1_000_000_000;

    // User Data Management
    var userProjectsCanistersRef : H.HashMap<UserPrincipal, H.HashMap<CanisterProjectID, [ProjectID]>> = H.HashMap(1, Text.equal, Text.hash);
    var projectCanister : CanisterProjectID = "";

    // User Logic Management
    public query func version() : async Text {
        return "0.0.1";
    };

    // Canister Logic Management
    private func create_project_canister() : async () {
        let tags = [ACTOR_NAME, "create_project_canister"];

        // create canister
        Cycles.add(cycleAmount);
        let projectActor = await Project.Project();
        let principal = Principal.fromActor(projectActor);
        let canisterProjectID = Principal.toText(principal);

        projectCanister := canisterProjectID;

        await Logger.log_event(tags, debug_show(("Create Project: ", canisterProjectID)));
    };

    public shared (msg) func heart_beat() : async ()  {
        let tags = [ACTOR_NAME, "heartbeat"];

        if (projectCanister.size() < 1) {
            await Logger.log_event(tags, debug_show(("Initialize: Project Canister =>", projectCanister)));

            await create_project_canister();
        };

         await Logger.log_event(tags, debug_show(("End: Project Canister =>", projectCanister)));
    };
};
