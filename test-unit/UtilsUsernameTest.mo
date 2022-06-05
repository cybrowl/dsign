import Utils  "../src/service_username/utils";
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
  describe("UsernameUtils.is_valid_username()", [
    it("should get false from invalid username", do {
      let username = "Mishicat";
      let isValid = Utils.is_valid_username(username);

      assertFalse(isValid);
    }),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}