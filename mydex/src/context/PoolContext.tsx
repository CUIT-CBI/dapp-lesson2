import { createContext, useEffect, useState } from "react";
import { ethers } from "ethers";
import {
  ExchangeETHAbi,
  ExchangeTokenAbi,
  MyFTAbi,
  FactoryAbi,
  FactoryAddress,
} from "../utils/constant";

//  @ts-ignore
export const PoolContext = createContext();

//  @ts-ignore
const { ethereum } = window;

const { getAddress, parseEther, formatEther } = ethers.utils;

export const PoolContextProvider = ({ children }) => {
  const [tokenAAmount, setTokenAAmount] = useState(0);
  const [tokenBAmount, setTokenBAmount] = useState(0);
  let [tokenA, setTokenA] = useState(
    "0x0000000000000000000000000000000000000000"
  );
  let [tokenB, setTokenB] = useState(
    "0x0000000000000000000000000000000000000000"
  );
  const [poolInfo, setPoolInfo] = useState({
    address: "",
    SymbolA: "",
    SymbolB: "",
    reserveA: "",
    reserveB: "",
  });
  const createPool = async () => {
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    const factory = new ethers.Contract(FactoryAddress, FactoryAbi, signer);
    const tokenAAddress = getAddress(tokenA < tokenB ? tokenA : tokenB);
    const tokenBAddress = getAddress(tokenA > tokenB ? tokenA : tokenB);
    if (
      tokenAAddress === getAddress("0x0000000000000000000000000000000000000000")
    ) {
      await (await factory.createExchangeETH(tokenBAddress)).wait();
    } else {
      await (
        await factory.createExchangeToken(tokenBAddress, tokenAAddress)
      ).wait();
    }
    return true;
  };

  const approve = async (token: string, amount: string) => {
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    const Token = new ethers.Contract(getAddress(token), MyFTAbi, signer);
    try {
      await (await Token.approve(poolInfo.address, parseEther(amount))).wait();
    } catch (err) {
      console.error(err);
      return false;
    }
    return true;
  };

  const getSymbol = (token: string) => {
    if (token === "0x0000000000000000000000000000000000000000") {
      return "ETH";
    } else {
      const provider = new ethers.providers.Web3Provider(ethereum);
      const signer = provider.getSigner();
      const Token = new ethers.Contract(getAddress(token), MyFTAbi, signer);
      let res = Token.symbol();
      return res;
    }
  };

  const getPoolInfo = async () => {
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    const factory = new ethers.Contract(FactoryAddress, FactoryAbi, signer);
    let tokenBAddress = getAddress(tokenB);
    let tokenAAddress = getAddress(tokenA);
    const res = (
      await factory.ifPairExist(tokenBAddress, tokenAAddress)
    ).toString();
    if (res === "true") {
      let SymbolA = "ETH";
      let SymbolB = "ETH";
      let reserveA = "";
      let reserveB = "";
      let pairAddress = await factory.getPair(tokenAAddress, tokenBAddress);
      if (
        tokenAAddress ===
        getAddress("0x0000000000000000000000000000000000000000")
      ) {
        const TokenB = new ethers.Contract(tokenB, MyFTAbi, signer);
        SymbolB = (await TokenB.symbol()).toString();
        const ExchangeETH = new ethers.Contract(
          pairAddress,
          ExchangeETHAbi,
          signer
        );
        reserveA = formatEther((await ExchangeETH.getEthReserve()).toString());
        reserveB = formatEther(
          (await ExchangeETH.getTokenReserve()).toString()
        );
      } else if (
        tokenBAddress ===
        getAddress("0x0000000000000000000000000000000000000000")
      ) {
        const TokenA = new ethers.Contract(
          tokenAAddress.toString(),
          MyFTAbi,
          signer
        );
        SymbolB = (await TokenA.symbol()).toString();
        const ExchangeETH = new ethers.Contract(
          pairAddress,
          ExchangeETHAbi,
          signer
        );
        reserveA = formatEther((await ExchangeETH.getEthReserve()).toString());
        reserveB = formatEther(
          (await ExchangeETH.getTokenReserve()).toString()
        );
      } else {
        if (tokenA > tokenB) {
          let temp = tokenA;
          tokenA = tokenB;
          tokenB = temp;
        }
        const tokenAAddressTemp = new ethers.Contract(tokenA, MyFTAbi, signer);
        SymbolA = (await tokenAAddressTemp.symbol()).toString();
        const tokenBAddressTemp = new ethers.Contract(tokenB, MyFTAbi, signer);
        SymbolB = (await tokenBAddressTemp.symbol()).toString();
        const ExchangeTemp = new ethers.Contract(
          pairAddress,
          ExchangeTokenAbi,
          signer
        );
        reserveA = formatEther((await ExchangeTemp.reserveA()).toString());
        reserveB = formatEther((await ExchangeTemp.reserveB()).toString());
      }
      setPoolInfo({
        address: pairAddress,
        SymbolA: SymbolA,
        SymbolB: SymbolB,
        reserveA: reserveA,
        reserveB: reserveB,
      });
    }
    return res;
  };
  const addLiquidity = async (amount1: number, amount2: number) => {
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    if (poolInfo.SymbolA === "ETH" || poolInfo.SymbolB === "ETH") {
      const Exchange = new ethers.Contract(
        poolInfo.address,
        ExchangeETHAbi,
        signer
      );
      try {
        await (
          await Exchange.addLiquidity(parseEther(amount1.toString()), {
            value: parseEther(amount2.toString()),
          })
        ).wait();
      } catch (err) {
        console.error(err);
        return false;
      }
    } else {
      const Exchange = new ethers.Contract(
        poolInfo.address,
        ExchangeTokenAbi,
        signer
      );
      try {
        let temp = amount1;
        amount1 = tokenA < tokenB ? amount1 : amount2;
        amount2 = tokenA < tokenB ? amount2 : temp;
        await (
          await Exchange.addLiquidity(
            parseEther(amount1.toString()),
            parseEther(amount2.toString())
          )
        ).wait();
      } catch (err) {
        console.error(err);
        return false;
      }
    }
    return true;
  };
  const removeLiquidity = async (amount1: number) => {
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    if (poolInfo.SymbolA === "ETH" || poolInfo.SymbolB === "ETH") {
      const Exchange = new ethers.Contract(
        poolInfo.address,
        ExchangeETHAbi,
        signer
      );
      try {
        await (
          await Exchange.removeLiquidity(parseEther(amount1.toString()))
        ).wait();
      } catch (err) {
        console.error(err);
        return false;
      }
    } else {
      const Exchange = new ethers.Contract(
        poolInfo.address,
        ExchangeTokenAbi,
        signer
      );
      try {
        await (
          await Exchange.removeLiquidity(parseEther(amount1.toString()))
        ).wait();
      } catch (err) {
        console.error(err);
        return false;
      }
    }
    return true;
  };

  const swap = async (amount: string, minToken: string) => {
    amount = Number(amount).toFixed(18);
    minToken = Number(minToken).toFixed(18);
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();

    try {
      if (tokenA === "0x0000000000000000000000000000000000000000") {
        const Exchange = new ethers.Contract(
          poolInfo.address,
          ExchangeETHAbi,
          signer
        );
        await (
          await Exchange.ethToToken(parseEther(minToken), {
            value: parseEther(amount),
          })
        ).wait();
      } else if (tokenB === "0x0000000000000000000000000000000000000000") {
        const Exchange = new ethers.Contract(
          poolInfo.address,
          ExchangeETHAbi,
          signer
        );

        await (
          await Exchange.tokenToEth(parseEther(minToken), parseEther(amount))
        ).wait();
      } else {
        const Exchange = new ethers.Contract(
          poolInfo.address,
          ExchangeTokenAbi,
          signer
        );
        tokenA > tokenB
          ? await (
              await Exchange.tokenBToA(parseEther(minToken), parseEther(amount))
            ).wait()
          : await (
              await Exchange.tokenAToB(parseEther(minToken), parseEther(amount))
            ).wait();
      }
    } catch (err) {
      console.error(err);
      return false;
    }
    return true;
  };

  const getAmountOfExchangeETH = async (amount: number, token: string) => {
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    const factory = new ethers.Contract(FactoryAddress, FactoryAbi, signer);
    let pairAddress = await factory.getPair(
      getAddress(tokenA),
      getAddress(tokenB)
    );
    const Exchange = new ethers.Contract(pairAddress, ExchangeETHAbi, signer);
    if (token == "0x0000000000000000000000000000000000000000") {
      let res = (
        await Exchange.getTokenAmount(parseEther(amount.toString()))
      ).toString();
    } else {
      let res = (
        await Exchange.getEthAmount(parseEther(amount.toString()))
      ).toString();
    }
  };
  return (
    <PoolContext.Provider
      value={{
        getPoolInfo,
        tokenA,
        setTokenA,
        tokenB,
        setTokenB,
        poolInfo,
        getSymbol,
        createPool,
        tokenAAmount,
        setTokenAAmount,
        tokenBAmount,
        setTokenBAmount,
        approve,
        addLiquidity,
        removeLiquidity,
        swap,
      }}
    >
      {children}
    </PoolContext.Provider>
  );
};

export default PoolContext;
