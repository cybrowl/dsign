import { profile } from "canister/profile";

export async function ping() {
  try {
    const ping = await profile.ping();

    return ping;
  } catch (err) {
    console.error(err);
  }
}

export async function health() {
  try {
    const health = await profile.health();

    return health;
  } catch (err) {
    console.error(err);
  }
}