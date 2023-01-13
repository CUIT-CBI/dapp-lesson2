import { PoolContext } from "../../context/PoolContext";
import React, { useContext, useEffect, useState } from "react";
import { Button, Col, Input, Row, Statistic } from "antd";

const PoolInfo = () => {
  // @ts-ignore
  const {poolInfo,addLiquidity, tokenA, tokenB, approve,removeLiquidity,getSymbol} = useContext(PoolContext);
  const [tokenBAmount, setTokenBAmount] = useState(0);
  const [tokenAAmount, setTokenAAmount] = useState(0);

  const getAmountChange = (e) => {
    setTokenAAmount(e);
    setTokenBAmount(
      (e * Number(poolInfo.reserveB)) / Number(poolInfo.reserveA)
    );
  };
  const toAddLiquidity = async () => {
    let res;
    if (poolInfo.SymbolA === "ETH" || poolInfo.SymbolB === "ETH") {
      res = (
        await addLiquidity(
          poolInfo.SymbolA === "ETH" ? tokenBAmount : tokenAAmount,
          poolInfo.SymbolA === "ETH" ? tokenAAmount : tokenBAmount
        )
      ).toString();
    } else {
      res = (await addLiquidity(tokenAAmount, tokenBAmount)).toString();
    }
    if (res == "false") {
      alert("添加失败,请确保是否添加了授权");
    } else {
      alert("添加流动性成功,请重新点击查看流动池更新");
    }
  };


  const toApproveTokenA = async () => {
    let res =tokenA < tokenB? (await approve(tokenA, tokenAAmount.toString())).toString():
    (await approve(tokenB, tokenAAmount.toString())).toString()
    if (res === "false") {
      alert("授权TokenA失败");
    } else {
      alert("授权TokenA成功");
    }
  };
  const toRemoveLiquidity = async () => {
    let res;
    if (poolInfo.SymbolA === "ETH" || poolInfo.SymbolB === "ETH") {
      res = (
        await removeLiquidity(
          poolInfo.SymbolA === "ETH" ? tokenAAmount : tokenBAmount
        )
      ).toString();
    } else {
      res = (await removeLiquidity(tokenAAmount)).toString();
    }
    if (res == "true") {
      alert("移除成功");
    } else {
      alert("移除失败,请确保是否超出自己的持有量");
    }
  };
  const toApproveTokenB = async () => {
    let res = tokenA<tokenB? (await approve(tokenB, tokenBAmount.toString())).toString():
    (await approve(tokenA, tokenBAmount.toString())).toString()
    if (res === "false") {
      alert("授权TokenB失败");
    } else {
      alert("授权TokenB成功");
    }
  };

  return (
    <>
      <div style={{ textAlign: "center", marginTop: "7%" }}>
        <Row>
          <Col span={8} offset={3}>
            <p style={{ fontSize: "25px" }}>
              SymbolA:&nbsp;&nbsp;&nbsp;
              <span style={{ color: "red" }}>{poolInfo.SymbolA}</span>{" "}
            </p>
            <Statistic title="总量" value={poolInfo.reserveA} />
          </Col>
          <Col span={8} offset={3}>
            <p style={{ fontSize: "25px" }}>
              SymbolB:&nbsp;&nbsp;&nbsp;
              <span style={{ color: "red" }}>{poolInfo.SymbolB}</span>{" "}
            </p>
            <Statistic title="总量" value={poolInfo.reserveB} />
          </Col>
        </Row>
        <p
          style={{
            fontSize: "20px",
            color: "black",
            textAlign: "left",
            paddingLeft: "75px",
            paddingBottom: "5%",
            paddingTop: "6%",
          }}
        >
          输入要添加或者移除的 {poolInfo.SymbolA} 的数量:
        </p>
        <Input
          style={{ width: "70%", fontSize: "20px", padding: "20px,30px" }}
          onChange={(e) => {
            poolInfo.reserveA != 0
              ? getAmountChange(e.target.value)
              : setTokenAAmount(Number(e.target.value));
          }}
        />
        {poolInfo.reserveB != 0 ? (
          <>
            <p
              style={{
                fontSize: "20px",
                color: "black",
                textAlign: "left",
                paddingLeft: "75px",
                paddingBottom: "1%",
                paddingTop: "4%",
              }}
            >
              可以得到或者需要添加的 {poolInfo.SymbolB} 的数量:
            </p>
            <Input
              bordered={false}
              disabled={true}
              value={tokenBAmount}
              style={{ width: "70%", fontSize: "20px", padding: "20px,30px" }}
            />
          </>
        ) : (
          <>
            <p
              style={{
                fontSize: "20px",
                color: "black",
                textAlign: "left",
                paddingLeft: "75px",
                paddingBottom: "5%",
                paddingTop: "6%",
              }}
            >
              输入要添加或者移除的 {poolInfo.SymbolB} 的数量:
            </p>
            <Input
              style={{ width: "70%", fontSize: "20px", padding: "20px,30px" }}
              onChange={(e) => {
                setTokenBAmount(Number(e.target.value));
              }}
            />
          </>
        )}
      </div>
      <br />
      <br />
      <Row>
        <Col span={8} offset={4}>
          <Button
            size="large"
            disabled={poolInfo.SymbolA === "ETH"}
            type="primary"
            onClick={toApproveTokenA}
            style={{ width: 120 }}
          >
            授权 {poolInfo.SymbolA}
          </Button>
        </Col>
        <Col span={8} offset={2}>
          <Button
            size="large"
            disabled={poolInfo.SymbolB === "ETH"}
            type="primary"
            onClick={toApproveTokenB}
            style={{ width: 120 }}
          >
            授权 {poolInfo.SymbolB}
          </Button>
        </Col>
      </Row>
      <Button
        onClick={toAddLiquidity}
        size="large"
        type="primary"
        style={{ marginTop: "20px", marginLeft: "150px", width: 210 }}
      >
        添加流动性
      </Button>
      <br />
      <Button
        size="large"
        type="primary"
        style={{ marginTop: "20px", marginLeft: "150px", width: 210 }}
        onClick={toRemoveLiquidity}
        disabled={poolInfo.reserveA==0}
      >
        移除流动性
      </Button>
    </>
  );
};

export default PoolInfo;
