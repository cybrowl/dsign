const test = require("tape");
const canisterIds = require("../.dfx/local/canister_ids.json");
const fetch = require("node-fetch");
const { getActor } = require("./actor");

global.fetch = fetch;

test("Profile: ping()", async function (t) {
  const canisterId = canisterIds.profile.local;

  const profile = await getActor(canisterId);
  const response = await profile.ping();

  t.equal(typeof response, "string");
  t.equal(response, "pong");
});
