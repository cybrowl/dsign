<script>
  import { ping } from "./api/profile";

  let responses = [];

  async function handleClick() {
    const pingResponse = await ping();
    responses = [...responses, pingResponse];
  }
</script>

<main>
  <a href="https://dsign.ic" target="_blank" rel="noopener noreferrer" class="logo">
    <img src="images/dfinity.svg" alt="DFINITY logo" />
  </a>

  <div>
    <img src="images/mishicat.png" alt="MishiCat" on:click={handleClick} />
  </div>

  <h1>MishiCat</h1>

  <h1 class="text-3xl font-bold underline">Tailwind CSS</h1>

  <div>
    <ul>
      {#each responses as response}
        <li>
          {response}
        </li>
      {/each}
    </ul>
  </div>
</main>

<style lang="postcss" global>
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

  img {
    height: 22px;
  }
  .logo {
    display: inline-block;
    margin-bottom: 64px;
    margin-top: 24px;
  }

  main {
    text-align: center;
    padding: 1em;
  }

  div > img {
    height: 500px;
  }

  h1 {
    text-transform: uppercase;
    font-size: 3em;
    font-weight: 400;
    line-height: 1.09;
  }

  @media (min-width: 640px) {
    main {
      max-width: 800px;
      margin: 0 auto;
    }
    h1 {
      font-size: 4em;
    }
  }
</style>
