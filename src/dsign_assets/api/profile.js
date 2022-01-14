import { profile } from "canister/profile";

export async function ping() {
  try {
    const ping = await profile.ping();

    return ping;
  } catch (err) {
    console.error(err);
  }
}