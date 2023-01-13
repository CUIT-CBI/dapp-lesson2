import React from "react";
import { PoolContextProvider } from "../context/PoolContext";
import PoolForm from '../components/pool/PoolForm'

const Pool: React.FC = () => {
  return (
    <PoolContextProvider>
      <PoolForm />
    </PoolContextProvider>
  );
};


export default Pool;
