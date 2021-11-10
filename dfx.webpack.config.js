const path = require("path")

let localCanisters, prodCanisters, canisters

function initCanisterIds() {
  try {
    localCanisters = require(path.resolve(
      ".dfx",
      "local",
      "canister_ids.json"
    ))
  } catch (error) {
    console.log('------------------------------------');
    console.log("No local canister_ids.json found. Continuing production", error);
    console.log('------------------------------------');
  }
  try {
    prodCanisters = require(path.resolve("canister_ids.json"))
  } catch (error) {
    console.log('------------------------------------');
    console.log("No production canister_ids.json found. Continuing with local");
    console.log('------------------------------------');
  }

  const network = process.env.NODE_ENV === "production" ? "ic" : "local";

  console.log('------------------------------------');
  console.log(`initCanisterIds: network=${network}`);
  console.log('------------------------------------');

  canisters = network === "local" ? localCanisters : prodCanisters

  for (const canister in canisters) {
    console.log('------------------------------------');
    console.log(`canister.toUpperCase():`, canister.toUpperCase());
    console.log('------------------------------------');

    process.env[`${canister.toUpperCase()}_CANISTER_ID`] =
      canisters[canister][network]
  }
}

module.exports = {
  initCanisterIds: initCanisterIds,
}