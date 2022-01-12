import "./tailwind.css";
import { ping } from "./api/profile";
import MishiCat from "../public/mishicat.png";

const App = () => {
  return (
    <div className="App bg-[#eee] h-[100vh] flex items-center justify-center flex-col">
      <h1 className="font-bold text-4xl text-[#333]">Hi 👋</h1>
      <p className="text-sm font-italic m-[3px]">My Name is MishiCat</p>
      <img src={MishiCat} onClick={() => ping()} />
    </div>
  );
};

export default App;
