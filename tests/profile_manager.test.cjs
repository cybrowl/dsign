const test = require("tape");
const fetch = require("node-fetch");
const { getActor } = require("./actor.cjs");
const canisterIds = require("../.dfx/local/canister_ids.json");
const { idlFactory } = require("../.dfx/local/canisters/profile_manager/profile_manager.did.test.cjs");

global.fetch = fetch;

// test("Profile Manager: ping()", async function (t) {
//   const canisterId = canisterIds.profile_manager.local;

//   const profileManager = await getActor(canisterId, idlFactory);
//   const response = await profileManager.ping();

//   t.equal(typeof response, "string");
//   t.equal(response, "meow");
// });

// test("Profile Manager: set_name() and get_name()", async function (t) {
//   const canisterId = canisterIds.profile_manager.local;

//   const profileManager = await getActor(canisterId, idlFactory);
//   await profileManager.set_username("kittycat");

//   const response = await profileManager.get_username("kittycat");
//   const response2 = await profileManager.get_canister("kittycat");

//   console.log("response: ", response);
//   console.log("response2: ", response2);

//   t.equal(typeof response[0], "string");
// });