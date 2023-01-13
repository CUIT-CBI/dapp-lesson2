import { ConnectionProvider } from "../context/ConnectContext";
import { Connect, Welcome } from "../components/home";

const Home = () => (
  <ConnectionProvider>
    <div style={{ paddingTop: "10%" }}>
      <Welcome />
      <Connect />
    </div>
  </ConnectionProvider>
);
export default Home;
