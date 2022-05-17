import Utils  "../service_account_settings/utils";
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
  describe("Utils: get_username", [
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
  describe("Utils: is_valid_username", [
    it("should return true for valid username", do {
      let username : Text = "mishicat";
      let isValid = Utils.is_valid_username(username);

      assertTrue(isValid);
    }),
    it("should return true for valid username", do {
      let username : Text = "mishic4t";
      let isValid = Utils.is_valid_username(username);

      assertTrue(isValid);
    }),
    it("should return true for valid username", do {
      let username : Text = "mishi123";
      let isValid = Utils.is_valid_username(username);

      assertTrue(isValid);
    }),
    it("should return true for valid username", do {
      let username : Text = "2323232";
      let isValid = Utils.is_valid_username(username);

      assertTrue(isValid);
    }),
    it("should return false for invalid username", do {
      let username : Text = "Mishicat";
      let isValid = Utils.is_valid_username(username);

      assertFalse(isValid);
    }),
    it("should return false for invalid username", do {
      let username : Text = "mish!";
      let isValid = Utils.is_valid_username(username);

      assertFalse(isValid);
    }),
        it("should return false for invalid username", do {
      let username : Text = "";
      let isValid = Utils.is_valid_username(username);

      assertFalse(isValid);
    }),
    it("should return false for invalid username", do {
      let username : Text = "misH";
      let isValid = Utils.is_valid_username(username);

      assertFalse(isValid);
    }),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}