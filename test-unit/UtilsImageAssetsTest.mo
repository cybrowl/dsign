import Utils "../src/service_assets_img/utils";
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
	describe(
		"ImageAssets.is_valid_image()",
		[
			it(
				"should return true for GIF image",
				do {
					let gifImage : Blob = Blob.fromArray([71, 73, 70, 56]);
					let isValid = Utils.is_valid_image(gifImage);
					assertTrue(isValid);
				}
			),
			it(
				"should return true for PNG image",
				do {
					let pngImage : Blob = Blob.fromArray([137, 80, 78, 71]);
					let isValid = Utils.is_valid_image(pngImage);
					assertTrue(isValid);
				}
			),
			it(
				"should return true for JPEG image",
				do {
					let jpgImage : Blob = Blob.fromArray([255, 216, 255, 224]);
					let isValid = Utils.is_valid_image(jpgImage);
					assertTrue(isValid);
				}
			),
			it(
				"should return true for JPEG2 image",
				do {
					let jpg2Image : Blob = Blob.fromArray([255, 216, 255, 225]);
					let isValid = Utils.is_valid_image(jpg2Image);
					assertTrue(isValid);
				}
			),
			it(
				"should return false for wrong PNG image",
				do {
					let pngImage : Blob = Blob.fromArray([137, 80, 78, 70]);
					let isValid = Utils.is_valid_image(pngImage);
					assertFalse(isValid);
				}
			),
			it(
				"should return false for wrong JPEG image",
				do {
					let jpgImage : Blob = Blob.fromArray([255, 216, 255, 223]);
					let isValid = Utils.is_valid_image(jpgImage);
					assertFalse(isValid);
				}
			)
		]
	),
	describe(
		"ImageAssets.get_image_id()",
		[
			it(
				"should return image id [local]",
				do {
					let url = "http://localhost:8080/image/snap/77R4744E1K56EFF1GEG31R09EE?canisterId=6cnwd-nyaaa-aaaaa-aabfa-cai";
					let expected = "77R4744E1K56EFF1GEG31R09EE";
					let image_id = Utils.get_image_id(url);
					assertTrue(Text.equal(image_id, expected));
				}
			),
			it(
				"should return image id [prod]",
				do {
					let url = "https://6cnwd-nyaaa-aaaaa-aabfa-cai.raw.ic0.app/image/snap/77R4744E1K56EFF1GEG31R09EE";
					let expected = "77R4744E1K56EFF1GEG31R09EE";
					let image_id = Utils.get_image_id(url);
					assertTrue(Text.equal(image_id, expected));
				}
			)
		]
	),
	describe(
		"ImageAssets.generate_image_url()",
		[
			it(
				"should return image asset url [prod]",
				do {
					let canister_id = "6cnwd-nyaaa-aaaaa-aabfa-cai";
					let image_id = "77R4744E1K56EFF1GEG31R09EE";
					let asset_type = "snap";
					let isProduction = true;
					let expected = "https://6cnwd-nyaaa-aaaaa-aabfa-cai.raw.ic0.app/image/snap/77R4744E1K56EFF1GEG31R09EE";
					let url = Utils.generate_image_url(canister_id, image_id, asset_type, isProduction);
					assertTrue(Text.equal(url, expected));
				}
			),
			it(
				"should return image asset url [local]",
				do {
					let canister_id = "6cnwd-nyaaa-aaaaa-aabfa-cai";
					let image_id = "77R4744E1K56EFF1GEG31R09EE";
					let asset_type = "snap";
					let isProduction = false;
					let expected = "http://localhost:8080/image/snap/77R4744E1K56EFF1GEG31R09EE?canisterId=6cnwd-nyaaa-aaaaa-aabfa-cai";
					let url = Utils.generate_image_url(canister_id, image_id, asset_type, isProduction);
					assertTrue(Text.equal(url, expected));
				}
			)
		]
	)
]);

if (success == false) {
	Debug.trap("Tests failed");
};
