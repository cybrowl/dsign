import Utils  "../src/service_snaps/utils";
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
  describe("Utils: get_image_id", [
    it("should get image_id from url", do {
      let url = "https://qoctq-giaaa-aaaaa-aaaea-cai.raw.ic0.app/snap_image/70KX5HX4X39606KF1SVY3X25QZ";
      let imageID = Utils.get_image_id(url);

      assertTrue(Text.equal(imageID, "70KX5HX4X39606KF1SVY3X25QZ"));
    }),
  ]),
  describe("Utils: generate_snap_image_url", [
    it("should generate snap image url", do {
      let snap_images_canister_id = "qoctq-giaaa-aaaaa-aaaea-cai";
      let image_id = "70KKS0195HX5MS56MQVGV02C1Z";
      let isProduction = true;

      let image_url = Utils.generate_snap_image_url(snap_images_canister_id, image_id, isProduction);

      let expected = "https://qoctq-giaaa-aaaaa-aaaea-cai.raw.ic0.app/snap_image/70KKS0195HX5MS56MQVGV02C1Z";

      assertTrue(Text.equal(image_url, expected));
    }),
  ]),
  describe("Utils: generate_snap_image_urls", [
    it("should generate snap image urls", do {
      let snap_images_canister_id = "qoctq-giaaa-aaaaa-aaaea-cai";
      let image_ids = ["70KKS0195HX5MS56MQVGV02C1Z", "70KMAVP65RQ88HQ1R2BM5ZWKPA"];
      let isProduction = true;

      let image_urls = Utils.generate_snap_image_urls(snap_images_canister_id, image_ids, isProduction);

      let expected = [
        "https://qoctq-giaaa-aaaaa-aaaea-cai.raw.ic0.app/snap_image/70KKS0195HX5MS56MQVGV02C1Z",
        "https://qoctq-giaaa-aaaaa-aaaea-cai.raw.ic0.app/snap_image/70KMAVP65RQ88HQ1R2BM5ZWKPA"
        ];

      assertTrue(Array.equal(image_urls, expected, isEq));
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