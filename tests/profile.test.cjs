const test = require("tape");
const fetch = require("node-fetch");
const { getActor } = require("./actor.cjs");
const canisterIds = require("../.dfx/local/canister_ids.json");
const { idlFactory } = require("../.dfx/local/canisters/profile/profile.did.test.cjs");

global.fetch = fetch;

test("Profile: ping()", async function (t) {
  const canisterId = canisterIds.profile.local;

  const profile = await getActor(canisterId, idlFactory);
  const response = await profile.ping();

  t.equal(typeof response, "string");
  t.equal(response, "meow");
});

test("Profile: get_canister_caller_principal()", async function (t) {
  const canisterId = canisterIds.profile.local;

  const profile = await getActor(canisterId, idlFactory);
  const response = await profile.get_canister_caller_principal();

  t.equal(typeof response, "string");
});
