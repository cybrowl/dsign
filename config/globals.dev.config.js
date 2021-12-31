import canisterIds from "ic-local-canister-ids";

export default function globals() {
  return {
    NODE_ENV: "production",
    canisterIds
  };
}
