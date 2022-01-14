const test = require("tape");
const { generateCanisterIds, generateCanisterAliases } = require("../config/dfx.config");

test("dfxConfig: generateCanisterAliases()", async function (t) {
  const aliases = generateCanisterAliases();

  const expected = {
    "local-canister-ids": "/Users/cyberowl/Projects/dsign/.dfx/local/canister_ids.json",
    "canister/profile": "/Users/cyberowl/Projects/dsign/config/declarations/profile.js",
    "idl/profile": "/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile/profile.did.js",
    "canister/dsign_assets": "/Users/cyberowl/Projects/dsign/config/declarations/dsign_assets.js",
    "idl/dsign_assets": "/Users/cyberowl/Projects/dsign/.dfx/local/canisters/dsign_assets/dsign_assets.did.js",
  };

  t.deepEqual(aliases, expected);
});

test("dfxConfig: generateCanisterIds()", async function (t) {
  const { canisterIds, network } = generateCanisterIds();

  const expected = {
    __Candid_UI: { local: "r7inp-6aaaa-aaaaa-aaabq-cai" },
    dsign_assets: { local: "rrkah-fqaaa-aaaaa-aaaaq-cai" },
    profile: { local: "ryjl3-tyaaa-aaaaa-aaaba-cai" },
  };

  t.deepEqual(canisterIds, expected);
});
