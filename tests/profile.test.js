const test = require("tape");
const fetch = require("node-fetch");
const { Ed25519KeyIdentity } = require("@dfinity/identity");
const {
  idlFactory,
} = require("../.dfx/local/canisters/profile/profile.did.test");

// Actor/Canister Testing

global.fetch = fetch;

const { HttpAgent, Actor } = require("@dfinity/agent");

const HOST = "http://127.0.0.1:8000/";
const canisterId = "ryjl3-tyaaa-aaaaa-aaaba-cai";

const getActor = async (canisterId) => {
  const identity = Ed25519KeyIdentity.generate();

  const agent = new HttpAgent({
    host: HOST,
    identity,
  });

  agent.fetchRootKey().catch((err) => {
    console.warn(
      "Unable to fetch root key. Check to ensure that your local replica is running"
    );
    console.error(err);
  });

  const actor = Actor.createActor(idlFactory, {
    agent: agent,
    canisterId,
  });

  return actor;
};

test("Profile: ping()", async function (t) {
  const profile = await getActor(canisterId);
  const response = await profile.ping();

  t.equal(typeof response, "string");
  t.equal(response, "pong");
});

// test("Profile: canisterSize()", async function (t) {
//   const profile = await getActor(canisterId);
//   const response = await profile.canisterSize();

//   console.log("response=>", response);

//   t.equal(typeof response, "int");
//   t.equal(response, "pong");
// });
