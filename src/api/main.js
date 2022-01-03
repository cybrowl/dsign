import { dsign } from "ic-canisters/dsign";

export async function greetActor() {
  try {
    const hello = await dsign.hello();
    console.log("hello: ", hello);

    return hello;
  } catch (err) {
    console.error(err);
  }
}
