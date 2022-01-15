import { Actor, HttpAgent } from "@dfinity/agent";

// imports and re-exports candid interface
import { idlFactory } from "idl/profile";
export { idlFactory } from "idl/profile";
import environment from "environment";

const env = environment();

console.log("profile env: ", env);

const canisterId = env.canisterIds.profile[env["DFX_NETWORK"]];

const createActor = (canisterId, options) => {
  const agent = new HttpAgent({ ...options?.agentOptions });

  // Fetch root key for certificate validation during development
  if (env.DFX_NETWORK !== "ic") {
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
