import { createContext, useEffect, useState } from "react";

//  @ts-ignore
export const ConnectContext = createContext();
//  @ts-ignore
const { ethereum } = window;

export const ConnectionProvider = ({ children }) => {
  const [currentAccount, setCurrentAccount] = useState("");
  const checkIfWalletIsConnect = async () => {
    try {
      if (!ethereum) return alert("No MetaMask.");

      const accounts = await ethereum.request({ method: "eth_accounts" });

      if (accounts.length) {
        setCurrentAccount(accounts[0]);
      }
    } catch (error) {
      console.error(error);
      alert("未连接");
    }
  };

  const connectWallet = async () => {
    try {
      if (!ethereum) return alert("Please install MetaMask.");
      const accounts = await ethereum.request({
        method: "eth_requestAccounts",
      });
      setCurrentAccount(accounts[0]);
      window.location.reload();
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    checkIfWalletIsConnect();
  }, []);

  return (
    <ConnectContext.Provider
      value={{
        currentAccount,
        connectWallet,
      }}
    >
      {children}
    </ConnectContext.Provider>
  );
};
