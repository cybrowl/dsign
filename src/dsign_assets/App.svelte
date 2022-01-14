<script>
  import { ping } from "./api/profile";

  async function handleClick() {
    alert("clicked");

    const pingResponse = await ping();

    alert(pingResponse);
    
    console.log("pingResponse:",  pingResponse);
  }
</script>

<main>
  <a href="https://dfinity.org" target="_blank" rel="noopener noreferrer" class="logo">
    <img src="images/dfinity.svg" alt="DFINITY logo" />
  </a>

  <div>
    <img src="images/mishicat.png" alt="MishiCat" />
  </div>

  <h1 on:click={handleClick}>MishiCat</h1>
</main>

<style>
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
