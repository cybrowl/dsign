import Utils  "../profile_service/utils";
import Debug "mo:base/Debug";
import Text "mo:base/Text";

import ActorSpec "./ActorSpec";
type Group = ActorSpec.Group;

let assertTrue = ActorSpec.assertTrue;
let describe = ActorSpec.describe;
let it = ActorSpec.it;
let skip = ActorSpec.skip;
let pending = ActorSpec.pending;
let run = ActorSpec.run;

let success = run([
  describe("Profile Service Avatar Test Suite", [
    describe("Parse URL", [
      it("should get username", do {
        let url = "https://dsign.ic/avatar/heyday";
        assertTrue(Text.equal(Utils.get_username(url)), "heyday");
      }),
    ]),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}