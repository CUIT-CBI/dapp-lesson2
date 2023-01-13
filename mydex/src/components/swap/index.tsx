import React, { useContext, useState } from "react";
import { Button, Col, Collapse, Form, Input, Popover, Row, Select } from "antd";
const { Option } = Select;
import { PoolContext } from "../../context/PoolContext";

const Swap: React.FC = () => {
  const { Panel } = Collapse;
  // @ts-ignore
  const { poolInfo,tokenA,getSymbol,tokenB,setTokenA,setTokenB,getPoolInfo,approve,swap }= useContext(PoolContext)
  const [inputAType, setInputAType] = useState("ERC20");
  const [inputBType, setInputBType] = useState("ERC20");
  const [symbolA, setSymbolA] = useState("未选择");
  const [symbolB, setSymbolB] = useState("未选择");
  const [amountB, setAmountB] = useState("0");
  const [amountA, setAmountA] = useState("0");
  const [slip, setSlip] = useState("1");

  const handChangeA = (val: string) => {
    setInputAType(val);
    val === "ETH"
      ? setSymbolA("ETH")
      : getSymbol(tokenA).then((res: any) => setSymbolA(res));
    val === "ETH"
      ? setTokenA("0x0000000000000000000000000000000000000000")
      : null;
  };
  const handChangeB = (val: string) => {
    setInputBType(val);
    val === "ETH"
      ? setSymbolB("ETH")
      : getSymbol(tokenB).then((res: any) => setSymbolB(res));
    val === "ETH"
      ? setTokenB("0x0000000000000000000000000000000000000000")
      : null;
  };
  const handChangeTypeA = async (e) => {
    setTokenA(e.target.value);
    await getSymbol(e.target.value).then((res: any) => setSymbolA(res));
  };
  const handChangeTypeB = async (e) => {
    setTokenB(e.target.value);
    await getSymbol(e.target.value).then((res: any) => setSymbolB(res));
  };

  const toApproveToken = async () => {
    let res = (await approve(tokenA, amountA.toString())).toString();
    if (res === "false") {
      alert("授权Token失败");
    } else {
      alert("授权Token成功");
    }
  };

  const handChangeAmount = async (e) => {
    let result = (await getPoolInfo()).toString();
    if (result === "false") {
      alert("流动池不存在");
    }
    setAmountA(e.target.value);
    let a;
    let b;
    symbolA !== poolInfo.SymbolA
      ? (a = Number(poolInfo.reserveA))
      : (a = Number(poolInfo.reserveB));
    symbolA === poolInfo.SymbolA
      ? (b = Number(poolInfo.reserveA))
      : (b = Number(poolInfo.reserveB));
    let res = (
      (Number(e.target.value) * a) /
      (b + Number(e.target.value))
    ).toString();
    setAmountB(res);
  };

  const toSwap = async () => {
    let res = await swap(
      amountA,
      ((Number(amountB) * 997 * (100 - Number(slip))) / 100000).toString()
    );
    alert(res);
  };

  const content1 = (
    <>
      <Select
        style={{ width: 100 }}
        onChange={handChangeA}
        disabled={inputBType === "ETH"}
        defaultValue="ERC20"
      >
        <Option value="ERC20">ERC20</Option>
        <Option value="ETH">ETH</Option>
      </Select>
      <Input
        style={{ width: "100%", height: "50px" }}
        onChange={(e) => {
          handChangeTypeA(e);
        }}
        placeholder={
          inputAType === "ETH" ? "选择ETH时不可输入" : "输入Token地址"
        }
        disabled={inputAType === "ETH"}
      />
    </>
  );

  const content2 = (
    <>
      <Select
        style={{ width: 100 }}
        onChange={handChangeB}
        disabled={inputAType === "ETH"}
        defaultValue="ERC20"
      >
        <Option value="ERC20">ERC20</Option>
        <Option value="ETH">ETH</Option>
      </Select>
      <Input
        style={{ width: "100%", height: "50px" }}
        onChange={(e) => {
          handChangeTypeB(e);
        }}
        placeholder={
          inputBType === "ETH" ? "选择ETH时不可输入" : "输入Token地址"
        }
        disabled={inputBType === "ETH"}
      />
    </>
  );

  return (
    <Row>
      <Col span={3} offset={3}>
        <div style={{ textAlign: "center" }}>
          <p
            style={{
              fontSize: "90px",
              fontFamily: "Segoe Script",
              color: "skyblue",
              marginTop: "100%",
            }}
          >
            Swap
          </p>
        </div>
      </Col>
      <Col span={15} offset={3}>
        <div
          style={{
            width: "60%",
            margin: "0 auto",
            marginTop: "1%",
            textAlign: "center",
            paddingInline: "30px",
            border: "outset skyblue",
          }}
        >
          <Form style={{ marginTop: "5%", marginBottom: "20%" }}>
            <Form.Item
              noStyle
              rules={[{ required: true, message: "代币类型必须要选择" }]}
            >
              <span style={{ fontSize: "20px" }}>tokenA :</span>
              <Popover placement="topLeft" title="代币类型" content={content1}>
                <Button
                  style={{
                    marginBottom: "20px",
                    marginLeft: "20px",
                    width: "100px",
                    color: "red",
                  }}
                >
                  {symbolA}
                </Button>
              </Popover>
            </Form.Item>
            <Form.Item>
              <Input
                placeholder="TokenA数量"
                onChange={(e) => handChangeAmount(e)}
                style={{ width: "70%", height: "40px" }}
              />
              <br />
              <span style={{ fontSize: "20px" }}>tokenB :</span>
              <Popover placement="topLeft" title="代币类型" content={content2}>
                <Button
                  style={{
                    marginLeft: "20px",
                    marginTop: "20px",
                    width: "100px",
                    color: "red",
                  }}
                >
                  {symbolB}
                </Button>
              </Popover>
            </Form.Item>
            <Form.Item>
              <Input
                disabled={true}
                placeholder="0"
                value={amountB}
                style={{
                  fontSize: "20px",
                  color: "black",
                  width: "70%",
                  height: "40px",
                }}
              />
            </Form.Item>
            <Collapse style={{ marginLeft: "60px" }} ghost>
              <Panel header="点击设置滑点相关信息:  " key="1">
                <span style={{ fontSize: "20px" }}>
                  减去0.3%手续费预计可得到:
                  <span style={{ fontSize: "20px", color: "blue" }}>
                    {(Number(amountB) * 997) / 1000}
                  </span>
                  <br />
                </span>
                <span style={{ fontSize: "20px" }}>设置滑点为</span>
                <Input
                  style={{ width: "10%", height: "30px" }}
                  defaultValue="1"
                  onChange={(e) => setSlip(e.target.value)}
                />
                <span style={{ fontSize: "20px" }}>%(默认为1%)</span>
                <br />
                <span style={{ fontSize: "20px" }}>
                  最低可获得:
                  {(Number(amountB) * 997 * (100 - Number(slip))) / 100000}
                </span>
              </Panel>
            </Collapse>

            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                disabled={inputAType === "ETH"}
                size="large"
                onClick={toApproveToken}
                style={{ width: "60%", marginTop: "20px" }}
              >
                授权
              </Button>
              <Button
                type="primary"
                htmlType="submit"
                size="large"
                onClick={toSwap}
                style={{ width: "60%", marginTop: "20px" }}
              >
                交换
              </Button>
            </Form.Item>
          </Form>
        </div>
      </Col>
    </Row>
  );
};

export default Swap;
