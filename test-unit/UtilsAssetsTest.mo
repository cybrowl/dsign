import Utils "../src/service_assets/utils";
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

func isEq(a : Text, b : Text) : Bool { a == b };

let success = run(
	[
		describe(
			"AssetsUtils.get_asset_id()",
			[
				it(
					"should get asset id from local env",
					do {
						let url = "http://127.0.0.1:8000/asset/asset_id?canisterId=qoctq-giaaa-aaaaa-aaaea-cai";
						let expected = "asset_id";
						let asset_id = Utils.get_asset_id(url);
						assertTrue(Text.equal(asset_id, expected));
					}
				),
				it(
					"should get asset id from prod env",
					do {
						let url = "https://qoctq-giaaa-aaaaa-aaaea-cai.raw.ic0.app/asset/asset_id";
						let expected = "asset_id";
						let asset_id = Utils.get_asset_id(url);
						assertTrue(Text.equal(asset_id, expected));
					}
				)
			]
		),
		describe(
			"AssetsUtils.generate_asset_url()",
			[
				it(
					"should generate asset image url",
					do {
						let canister_id = "qoctq-giaaa-aaaaa-aaaea-cai";
						let asset_id = "70KKS0195HX5MS56MQVGV02C1Z";
						let is_prod = true;
						let asset_url = Utils.generate_asset_url({ asset_id = asset_id; canister_id = canister_id; is_prod = is_prod });
						let expected = "https://qoctq-giaaa-aaaaa-aaaea-cai.raw.ic0.app/asset/70KKS0195HX5MS56MQVGV02C1Z";
						assertTrue(Text.equal(asset_url, expected));
					}
				)
			]
		)
	]
);

if (success == false) {
	Debug.trap("Tests failed");
};
