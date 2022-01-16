import { profile } from "$ICprofile";

export async function ping() {
  try {
    console.log("profile: ", profile);

    const ping = await profile.ping();

    return ping;
  } catch (err) {
    console.error(err);
  }
}