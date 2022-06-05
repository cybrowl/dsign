import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import H "mo:base/HashMap";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import Logger "canister:logger";
import Project "Project";
import Types "./types";

actor ProjectMain {
    let ACTOR_NAME : Text = "ProjectMain";
    let cycleAmount : Nat = 1_000_000_000;

    // User Logic Management
    public query func version() : async Text {
        return "0.0.1";
    };
};
