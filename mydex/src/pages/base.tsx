import { Outlet } from "react-router-dom";
import BaseLayout from "../components/Layout";


function Base() {
  return (
    <div>
      <BaseLayout />
      <div
        style={{
          height: "690px",
          maxHeight: "900px",
          background: "linear-gradient(to bottom , white , skyblue)",
        }}
      >
        <Outlet />
      </div>
    </div>
  );
}

export default Base;
