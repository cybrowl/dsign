const path = require("path");
const dfxJson = require("../dfx.json");

function generateCanisterAliases() {
  const aliases = Object.entries(dfxJson.canisters).reduce((acc, [name]) => {
    // Get the network name, or `local` by default.
    const networkName = process.env["DFX_NETWORK"] || "local";
    const outputRoot = path.join(
      __dirname,
      "..",
      ".dfx",
      networkName,
      "canisters",
      name
    );

    return {
      ...acc,
      ["ic-canisters/" + name]: path.join(
        __dirname,
        "/canisters/" + name + ".js"
      ),
      ["ic-local-canister-ids"]: path.join(
        __dirname,
        "..",
        ".dfx",
        networkName,
        "canister_ids.json"
      ),
      ["ic-idl/" + name]: path.join(outputRoot, name + ".did.js"),
    };
  }, {});

  return aliases;
}

function generateCanisterIds() {
  let localCanisters, prodCanisters, canisters;

  try {
    localCanisters = require(path.resolve(
      ".dfx",
      "local",
      "canister_ids.json"
    ));
  } catch (error) {
    console.log("------------------------------------");
    console.log("No local canister_ids.json found. Continuing production");
    console.log("------------------------------------");
  }

  try {
    prodCanisters = require(path.resolve(__dirname, "canister_ids.json"));
  } catch (error) {
    console.log("------------------------------------");
    console.log("No production canister_ids.json found. Continuing with local");
    console.log("------------------------------------");
  }

  const network =
    process.env.DFX_NETWORK ||
    (process.env.NODE_ENV === "production" ? "ic" : "local");

  canisters = network === "local" ? localCanisters : prodCanisters;

  for (const canister in canisters) {
    process.env[`${canister.toUpperCase()}_CANISTER_ID`] =
      canisters[canister][network];
  }
}

module.exports = {
  generateCanisterIds,
  generateCanisterAliases,
};
