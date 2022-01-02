import { Actor, HttpAgent } from "@dfinity/agent";

// Imports and re-exports candid interface
import { idlFactory } from "ic-idl/dsign";
export { idlFactory } from "ic-idl/dsign";
import globals from "globals";

const config = globals();

console.log("config: ", config);

export const canisterId = config.canisterIds.dsign[config["DFX_NETWORK"]];

export const createActor = (canisterId, options) => {
  const agent = new HttpAgent({ ...options?.agentOptions });

  // Fetch root key for certificate validation during development
  if (config.DFX_NETWORK !== "production") {
    agent.fetchRootKey().catch((err) => {
      console.warn(
        "Unable to fetch root key. Check to ensure that your local replica is running"
      );
      console.error(err);
    });
  }

  // Creates an actor with using the candid interface and the HttpAgent
  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
    ...options?.actorOptions,
  });
};

export const dsign = createActor(canisterId);
