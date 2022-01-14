const path = require("path");
const dfxConfig = require("../dfx.json");

function generateCanisterAliases() {
  const dfxNetwork = process.env["DFX_NETWORK"] || "local";

  let aliases = {
    ["local-canister-ids"]: path.join(__dirname, "..", ".dfx", dfxNetwork, "canister_ids.json"),
  };

  if (dfxConfig.canisters) {
    const listOfCanisterNames = Object.keys(dfxConfig.canisters);

    aliases = listOfCanisterNames.reduce((acc, name) => {
      const outputRoot = path.join(__dirname, "..", ".dfx", dfxNetwork, "canisters", name);

      return {
        ...acc,
        ["canister/" + name]: path.join(__dirname, "/declarations/" + name + ".js"),
        ["idl/" + name]: path.join(outputRoot + "/" + name + ".did.js"),
      };
    }, aliases);
  }

  return aliases;
}

function generateCanisterIds() {
  let localCanisters, prodCanisters, canisterIds;

  try {
    localCanisters = require(path.resolve(".dfx", "local", "canister_ids.json"));
  } catch (error) {
    console.log("------------------------------------");
    console.log("No local canister_ids.json found. Continuing production");
    console.log("------------------------------------");
  }

  try {
    prodCanisters = require(path.resolve(__dirname, "..", "canister_ids.json"));
  } catch (error) {
    console.log("------------------------------------");
    console.log("No production canister_ids.json found. Continuing with local");
    console.log("------------------------------------");
  }

  const network = process.env.DFX_NETWORK || (process.env.NODE_ENV === "production" ? "ic" : "local");

  canisterIds = network === "local" ? localCanisters : prodCanisters;

  return { canisterIds, network };
}

function getEnvironmentVars(isDevelopment) {
  if (isDevelopment) {
    return path.resolve(__dirname, "env.dev.config.js");
  } else {
    return path.resolve(__dirname, "env.prod.config.js");
  }
}

module.exports = {
  generateCanisterIds,
  generateCanisterAliases,
  getEnvironmentVars,
};
