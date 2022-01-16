const path = require("path");
const dfxConfig = require("../dfx.json");

function generateCanisterAliases() {
  const dfxNetwork = process.env["DFX_NETWORK"] || "local";

  let aliases = {
    ["local-canister-ids"]: path.join(__dirname, "..", ".dfx", dfxNetwork, "canister_ids.json")
  };

  if (dfxConfig.canisters) {
    const listOfCanisterNames = Object.keys(dfxConfig.canisters);

    aliases = listOfCanisterNames.reduce((acc, name) => {
      const outputRoot = path.join(__dirname, "..", ".dfx", dfxNetwork, "canisters", name);

      return {
        ...acc,
        ["$IC" + name]: path.join(__dirname, "/declarations/" + name + ".js"),
        ["$IDL" + name]: path.join(outputRoot + "/" + name + ".did.js")
      };
    }, aliases);
  }

  return aliases;
}

function getEnvironmentPath(isDevelopment) {  
  if (isDevelopment) {
    return path.resolve(__dirname, "env.dev.config.js");
  } else {
    return path.resolve(__dirname, "env.prod.config.js");
  }
}

module.exports = {
  generateCanisterAliases,
  getEnvironmentPath
};
