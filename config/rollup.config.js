import { terser } from "rollup-plugin-terser";
import alias from "@rollup/plugin-alias";
import commonjs from "@rollup/plugin-commonjs";
import css from "rollup-plugin-css-only";
import inject from "rollup-plugin-inject";
import json from "@rollup/plugin-json";
import livereload from "rollup-plugin-livereload";
import replace from "@rollup/plugin-replace";
import resolve from "@rollup/plugin-node-resolve";
import svelte from "rollup-plugin-svelte";
const { generateCanisterIds, generateCanisterAliases } = require("./dfx.config");

const production = !process.env.ROLLUP_WATCH;

const { canisterIds, network } = generateCanisterIds();
const aliases = generateCanisterAliases();

function serve() {
  let server;

  function toExit() {
    if (server) server.kill(0);
  }

  return {
    writeBundle() {
      if (server) return;
      server = require("child_process").spawn("npm", ["run", "start", "--", "--dev"], {
        stdio: ["ignore", "inherit", "inherit"],
        shell: true,
      });

      process.on("SIGTERM", toExit);
      process.on("exit", toExit);
    },
  };
}

console.log("-------------------");
console.log("canisterIds: ", canisterIds);
console.log("network: ", network);
console.log("-------------------");

const frontend = {
  input: "src/dsign_assets/main.js",
  output: {
    sourcemap: true,
    format: "iife",
    name: "dsign",
    file: "public/build/bundle.js",
  },
  plugins: [
    alias({
      entries: {
        ...aliases,
      },
    }),

    svelte({
      compilerOptions: {
        // enable run-time checks when not in production
        dev: !production,
      },
    }),
    // we'll extract any component CSS out into
    // a separate file - better for performance
    css({ output: "bundle.css" }),

    // If you have external dependencies installed from
    // npm, you'll most likely need these plugins. In
    // some cases you'll need additional configuration -
    // consult the documentation for details:
    // https://github.com/rollup/plugins/tree/master/packages/commonjs
    resolve({
      preferBuiltins: false,
      browser: true,
      dedupe: ["svelte"],
    }),
    // Add canister ID's & network to the environment
    replace(
      Object.assign(
        {
          preventAssignment: false,
          "process.env.DFX_NETWORK": JSON.stringify(network),
          "process.env.NODE_ENV": JSON.stringify(production ? "production" : "development"),
        },
        ...Object.keys(canisterIds)
          .filter((canisterName) => canisterName !== "__Candid_UI")
          .map((canisterName) => ({
            ["process.env." + canisterName.toUpperCase() + "_CANISTER_ID"]: JSON.stringify(
              canisterIds[canisterName][network]
            ),
          }))
      )
    ),
    commonjs(),
    inject({
      Buffer: ["buffer", "Buffer"],
      process: "process/browser",
    }),
    json(),

    // In dev mode, call `npm run start` once
    // the bundle has been generated
    !production && serve(),

    // Watch the `public` directory and refresh the
    // browser on changes when not in production
    !production && livereload("public"),

    // If we're building for production (npm run build
    // instead of npm run dev), minify
    production && terser(),
  ],
  watch: {
    clearScreen: false,
  },
};

export default [frontend];
