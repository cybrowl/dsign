import Utils  "../profile_service/utils";
import Debug "mo:base/Debug";
import Text "mo:base/Text";

import ActorSpec "./ActorSpec";
type Group = ActorSpec.Group;

let assertTrue = ActorSpec.assertTrue;
let assertFalse = ActorSpec.assertFalse;
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
    it("should get username with extra /", do {
      let url = "https://dsign.ic/avatar/heyday&";
      let username = Utils.get_username(url);

      assertTrue(Text.equal(username, "heyday"));
    }),
  ]),
  describe("Image Validity", [
    it("should return true for PNG image", do {
      let pngImage : [Nat8] = [137,  80,  78,  71];
      let isValid = Utils.is_valid_image(pngImage);

      assertTrue(isValid);
    }),
    it("should return true for JPEG image", do {
      let pngImage : [Nat8] = [255, 216, 255, 224];
      let isValid = Utils.is_valid_image(pngImage);

      assertTrue(isValid);
    }),
    it("should return true for JPEG2 image", do {
      let pngImage : [Nat8] = [255, 216, 255, 225];
      let isValid = Utils.is_valid_image(pngImage);

      assertTrue(isValid);
    }),
    it("should return false for wrong PNG image", do {
      let pngImage : [Nat8] = [137,  80,  78,  70];
      let isValid = Utils.is_valid_image(pngImage);

      assertFalse(isValid);
    }),
    it("should return false for wrong JPEG image", do {
      let pngImage : [Nat8] = [255, 216, 255, 223];
      let isValid = Utils.is_valid_image(pngImage);

      assertFalse(isValid);
    }),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}