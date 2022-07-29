import Utils  "../src/service_profile_avatar/utils";
import Blob "mo:base/Blob";
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
  describe("Avatar.get_username()", [
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
  describe("Avatar.is_valid_image()", [
    it("should return true for GIF image", do {
      let gifImage : Blob = Blob.fromArray([71,  73,  70,  56]);
      let isValid = Utils.is_valid_image(gifImage);

      assertTrue(isValid);
    }),
    it("should return true for PNG image", do {
      let pngImage : Blob = Blob.fromArray([137,  80,  78,  71]);
      let isValid = Utils.is_valid_image(pngImage);

      assertTrue(isValid);
    }),
    it("should return true for JPEG image", do {
      let jpgImage : Blob = Blob.fromArray([255, 216, 255, 224]);
      let isValid = Utils.is_valid_image(jpgImage);

      assertTrue(isValid);
    }),
    it("should return true for JPEG2 image", do {
      let jpg2Image : Blob = Blob.fromArray([255, 216, 255, 225]);
      let isValid = Utils.is_valid_image(jpg2Image);

      assertTrue(isValid);
    }),
    it("should return false for wrong PNG image", do {
      let pngImage : Blob = Blob.fromArray([137,  80,  78,  70]);
      let isValid = Utils.is_valid_image(pngImage);

      assertFalse(isValid);
    }),
    it("should return false for wrong JPEG image", do {
      let jpgImage : Blob = Blob.fromArray([255, 216, 255, 223]);
      let isValid = Utils.is_valid_image(jpgImage);

      assertFalse(isValid);
    }),
  ])
]);

if(success == false){
  Debug.trap("Tests failed");
}