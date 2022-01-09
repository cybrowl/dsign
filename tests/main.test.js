const test = require("tape");
const fetch = require("node-fetch");
const { Ed25519KeyIdentity } = require("@dfinity/identity");

// Actor/Canister Testing

global.fetch = fetch;

const { HttpAgent, Actor } = require("@dfinity/agent");

const HOST = "http://127.0.0.1:8000/";
const canisterId = "rrkah-fqaaa-aaaaa-aaaaq-cai";

const idlFactory = ({ IDL }) => {
  return IDL.Service({
    greet: IDL.Func([IDL.Text], [IDL.Text], []),
    hello: IDL.Func([], [IDL.Text], ["query"]),
    hey: IDL.Func([IDL.Text], [IDL.Text], []),
  });
};

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

test("Main: hello()", async function (t) {
  const dsign = await getActor(canisterId);
  const response = await dsign.hello();

  t.equal(typeof response, "string");
});

test("Main: greet()", async function (t) {
  const dsign = await getActor(canisterId);
  const response = await dsign.greet("Jack");

  t.equal(typeof response, "string");
});

test("Main: hey()", async function (t) {
  const dsign = await getActor(canisterId);
  const response = await dsign.hey("Jane");

  t.equal(typeof response, "string");
});
