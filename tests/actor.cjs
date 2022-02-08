const { Ed25519KeyIdentity } = require("@dfinity/identity");
const { HttpAgent, Actor } = require("@dfinity/agent");

const HOST = "http://127.0.0.1:8000/";

const getActor = async (canisterId, idlFactory, identity) => {
  let mutableIdentity = identity;

  if (identity) {
    mutableIdentity = Ed25519KeyIdentity.generate();
  }

  const agent = new HttpAgent({
    host: HOST,
    identity: mutableIdentity
  });

  agent.fetchRootKey().catch((err) => {
    console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
    console.error(err);
  });

  const actor = Actor.createActor(idlFactory, {
    agent: agent,
    canisterId
  });

  return actor;
};

module.exports = {
  getActor
};
