import { Actor, HttpAgent } from "@dfinity/agent";

// Imports and re-exports candid interface
import { idlFactory } from "ic-idl/profile";
export { idlFactory } from "ic-idl/profile";
import globals from "globals";

const config = globals();

console.log("profile config: ", config);

export const canisterId = config.canisterIds.profile[config["DFX_NETWORK"]];

export const createActor = (canisterId, options) => {
  const agent = new HttpAgent({ ...options?.agentOptions });

  // Fetch root key for certificate validation during development
  if (config.DFX_NETWORK !== "ic") {
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

export const profile = createActor(canisterId);
