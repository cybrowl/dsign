const DFXWebPackConfig = require("./dfx.webpack.config")
DFXWebPackConfig.initCanisterIds()

const webpack = require("webpack")

// Make DFX_NETWORK available to Web Browser with default "local" if DFX_NETWORK is undefined
const EnvPlugin = new webpack.EnvironmentPlugin({
  DFX_NETWORK: "local",
})

module.exports = {
  swcMinify: true,
  webpack: (config) => {
    // Plugin
    config.plugins.push(EnvPlugin)

    // Alias
    config.resolve.alias = {
      ...config.resolve.alias,
      ...DFXWebPackConfig.aliases
    }

    console.log("alias: ", config.resolve.alias);
    
    // Important: return the modified config
    return config
  },
}
