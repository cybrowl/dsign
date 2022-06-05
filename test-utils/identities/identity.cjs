const { Secp256k1KeyIdentity } = require("@dfinity/identity");
const sha256 = require("sha256");
const fs = require("fs");
const Path = require("path");

const parseIdentity = (keyPath) => {
  const rawKey = fs
    .readFileSync(Path.join(__dirname, keyPath))
    .toString()
    .replace("-----BEGIN EC PRIVATE KEY-----", "")
    .replace("-----END EC PRIVATE KEY-----", "")
    .trim();

  const rawBuffer = Uint8Array.from(rawKey).buffer;

  const privKey = Uint8Array.from(sha256(rawBuffer, { asBytes: true }));

  // Initialize an identity from the secret key
  return Secp256k1KeyIdentity.fromSecretKey(Uint8Array.from(privKey).buffer);
};

const default_identity = parseIdentity("secp256k1-priv-key-default.pem");
const keeper_of_coin_identity = parseIdentity("secp256k1-priv-key-keeper-of-coin.pem");

module.exports = {
  default_identity,
  keeper_of_coin_identity
};
