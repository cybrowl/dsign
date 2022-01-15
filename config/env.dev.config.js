import canisterIds from "local-canister-ids";
console.log('%c%s', 'color: #e50000', canisterIds);

export default function env() {
  return {
    DFX_NETWORK: "local",
    canisterIds
  };
}
