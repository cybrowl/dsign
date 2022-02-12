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
    it("should get username when params exist", do {
      let url = "https://dsign.ic/avatar/heyday?canisterId=qaa6y-5yaaa-aaaaa-aaafa-cai";
      let username = Utils.get_username(url);

      assertTrue(Text.equal(username, "heyday"));
    }),
    it("should get username params don't exist", do {
      let url = "https://dsign.ic/avatar/heyday";
      let username = Utils.get_username(url);

      assertTrue(Text.equal(username, "heyday"));
    }),
    it("should get username with extra /", do {
      let url = "https://dsign.ic/avatar/heyday/";
      let username = Utils.get_username(url);

      assertTrue(Text.equal(username, "heyday"));
    }),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}