import { terser } from "rollup-plugin-terser";
import alias from "@rollup/plugin-alias";
import commonjs from "@rollup/plugin-commonjs";
import css from "rollup-plugin-css-only";
import inject from "rollup-plugin-inject";
import json from "@rollup/plugin-json";
import sveltePreprocess from "svelte-preprocess";
import resolve from "@rollup/plugin-node-resolve";
import svelte from "rollup-plugin-svelte";
const { generateCanisterAliases, getEnvironmentPath } = require("./dfx.config");

const isDevelopment = process.env.DFX_NETWORK !== "ic";
const isProduction = process.env.DFX_NETWORK === "ic";

const aliases = generateCanisterAliases();
const environment = getEnvironmentPath(isDevelopment);

const frontend = {
  input: "src/dsign_assets/main.js",
  output: {
    sourcemap: true,
    format: "iife",
    name: "dsign",
    file: "public/build/bundle.js"
  },
  plugins: [
    alias({
      entries: {
        ...aliases,
        environment
      }
    }),
    svelte({
      compilerOptions: {
        dev: isDevelopment
      },
      preprocess: sveltePreprocess({
        sourceMap: isDevelopment,
        postcss: {
          plugins: [require("tailwindcss")(), require("autoprefixer")()]
        }
      })
    }),
    css({ output: "bundle.css" }),
    resolve({
      preferBuiltins: false,
      browser: true,
      dedupe: ["svelte"]
    }),
    commonjs(),
    inject({
      Buffer: ["buffer", "Buffer"]
    }),
    json(),
    isProduction && terser()
  ],
  watch: {
    clearScreen: false
  }
};

export default [frontend];
