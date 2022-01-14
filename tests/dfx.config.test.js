const test = require("tape");
const { generateCanisterIds, generateCanisterAliases } = require("../config/dfx.config");

test("dfxConfig: generateCanisterAliases()", async function (t) {
  const aliases = generateCanisterAliases();
  const expected = {
    "local-canister-ids": "/Users/cyberowl/Projects/dsign/.dfx/local/canister_ids.json",
    "canister/profile": "/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile/index.js",
    "idl/profile": "/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile/profile.did.js",
    "canister/dsign_assets": "/Users/cyberowl/Projects/dsign/.dfx/local/canisters/dsign_assets/index.js",
    "idl/dsign_assets": "/Users/cyberowl/Projects/dsign/.dfx/local/canisters/dsign_assets/dsign_assets.did.js",
  };

  t.deepEqual(aliases, expected);
});

test("dfxConfig: generateCanisterIds()", async function (t) {
  const canisterIds = generateCanisterIds();

  const expected = {
    canisterIds: {
      __Candid_UI: { local: "r7inp-6aaaa-aaaaa-aaabq-cai" },
      dsign_assets: { local: "rrkah-fqaaa-aaaaa-aaaaq-cai" },
      profile: { local: "ryjl3-tyaaa-aaaaa-aaaba-cai" },
    },
    network: "local",
  };

  t.deepEqual(canisterIds, expected);
});
