const test = require("tape");
const fetch = require("node-fetch");
const { getActor } = require("./actor");
const canisterIds = require("../.dfx/local/canister_ids.json");
const { idlFactory } = require("../.dfx/local/canisters/profile/profile.did.test");

global.fetch = fetch;

test("Profile: ping()", async function (t) {
  const canisterId = canisterIds.profile.local;

  const profile = await getActor(canisterId, idlFactory);
  const response = await profile.ping();

  t.equal(typeof response, "string");
  t.equal(response, "pong");
});

test("Profile: health()", async function (t) {
  const canisterId = canisterIds.profile.local;

  const profile = await getActor(canisterId, idlFactory);
  const response = await profile.health();

  t.equal(typeof response, "string");
  t.equal(response, "good");
});
