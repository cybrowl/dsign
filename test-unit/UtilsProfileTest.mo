import Utils  "../src/service_profile/utils";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Array "mo:base/Array";

import ActorSpec "./ActorSpec";
type Group = ActorSpec.Group;

let assertTrue = ActorSpec.assertTrue;
let assertFalse = ActorSpec.assertFalse;
let describe = ActorSpec.describe;
let it = ActorSpec.it;
let skip = ActorSpec.skip;
let pending = ActorSpec.pending;
let run = ActorSpec.run;

func isEq(a: Text, b: Text): Bool { a == b };

let success = run([
  describe("ProfileUtils.generate_avatar_url()", [
    it("should generate avatar url in local env", do {
        let avatarCanisterId = "qoctq-giaaa-aaaaa-aaaea-cai";
        let username = "mishicat";
        let isProduction = false;

        let expected = "http://127.0.0.1:8000/avatar/mishicat?canisterId=qoctq-giaaa-aaaaa-aaaea-cai";
        let avatar_url = Utils.generate_avatar_url(avatarCanisterId, username, isProduction);

        assertTrue(Text.equal(avatar_url, expected));
    }),
    it("should generate avatar url in prod env", do {
        let avatarCanisterId = "qoctq-giaaa-aaaaa-aaaea-cai";
        let username = "mishicat";
        let isProduction = true;

        let expected = "https://qoctq-giaaa-aaaaa-aaaea-cai.raw.ic0.app/avatar/mishicat";
        let avatar_url = Utils.generate_avatar_url(avatarCanisterId, username, isProduction);

        assertTrue(Text.equal(avatar_url, expected));
    }),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}