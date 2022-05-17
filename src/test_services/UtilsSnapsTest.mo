import Utils  "../service_snaps/utils";
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
  describe("Utils: get_image_id", [
    it("LOCAL: should get username when params exist", do {
      let url = "http://127.0.0.1:8000/mishicat/snap/image/6Z61B30JFYWX0Y9TV04PQBMYEM?canisterId=va76m-bqaaa-aaaaa-aaayq-cai";
      let imageID = Utils.get_image_id(url);

      assertTrue(Text.equal(imageID, "6Z61B30JFYWX0Y9TV04PQBMYEM"));
    }),
  ]),
  describe("Utils: is_valid_image", [
    it("should return true for GIF image", do {
      let gifImage : [Nat8] = [71,  73,  70,  56];
      let isValid = Utils.is_valid_image(gifImage);

      assertTrue(isValid);
    }),
    it("should return true for PNG image", do {
      let pngImage : [Nat8] = [137,  80,  78,  71];
      let isValid = Utils.is_valid_image(pngImage);

      assertTrue(isValid);
    }),
    it("should return true for JPEG image", do {
      let jpgImage : [Nat8] = [255, 216, 255, 224];
      let isValid = Utils.is_valid_image(jpgImage);

      assertTrue(isValid);
    }),
    it("should return true for JPEG2 image", do {
      let jpg2Image : [Nat8] = [255, 216, 255, 225];
      let isValid = Utils.is_valid_image(jpg2Image);

      assertTrue(isValid);
    }),
    it("should return false for wrong PNG image", do {
      let pngImage : [Nat8] = [137,  80,  78,  70];
      let isValid = Utils.is_valid_image(pngImage);

      assertFalse(isValid);
    }),
    it("should return false for wrong JPEG image", do {
      let jpgImage : [Nat8] = [255, 216, 255, 223];
      let isValid = Utils.is_valid_image(jpgImage);

      assertFalse(isValid);
    }),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}