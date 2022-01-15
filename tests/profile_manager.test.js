const test = require("tape");
const fetch = require("node-fetch");
const { getActor } = require("./actor");
const canisterIds = require("../.dfx/local/canister_ids.json");
const { idlFactory } = require("../.dfx/local/canisters/profile_manager/profile_manager.did.test");

global.fetch = fetch;

test("Profile Manager: ping()", async function (t) {
  const canisterId = canisterIds.profile_manager.local;

  const profileManager = await getActor(canisterId, idlFactory);
  const response = await profileManager.ping();

  t.equal(typeof response, "string");
  t.equal(response, "meow");
});
