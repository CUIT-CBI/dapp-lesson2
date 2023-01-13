import React, { useContext, useState } from "react";
import { Alert, Button, Form, Input, Row, Select, Col, Spin } from "antd";
import { PoolContext } from "../../context/PoolContext";
import PoolInfo from "./PoolInfo";
import { RightCircleTwoTone } from "@ant-design/icons";

const { Option } = Select;

const PoolForm = () => {
  // @ts-ignore
  const {getPoolInfo,setTokenA,setTokenB,createPool,tokenA,tokenB,  } = useContext(PoolContext);
  const [formState, setFormState] = useState(0);
  const [loadingMessage, setLoadingMessage] = useState("请输入token后点击查看");
  let loading = <span></span>;
  if (loadingMessage === "流动池创建中") {
    loading = (
      <Spin style={{ width: "100%" }} tip={loadingMessage} size="large"></Spin>
    );
  } else {
    loading = <span></span>;
  }
  const toCreated = async () => {
    setFormState(0);
    setLoadingMessage("流动池创建中");
    const res = await createPool();
    if (res.toString() === "true") {
      setFormState(2);
      alert("成功");
    } else {
      alert("失败");
      setFormState(0);
    }
    setLoadingMessage("请输入token后点击查看");
    onFinish();
  };
  var layout;
  if (formState === 1) {
    layout = (
      <Alert
        message="添加交易池"
        description="当前交易池不存在,是否创建交易池?"
        type="info"
        style={{ margin: "auto", width: "40%" }}
        onClose={() => setFormState(0)}
        action={
          <Button size="large" type="primary" onClick={toCreated}>
            创建
          </Button>
        }
        closable
      />
    );
  }
  const [inputAType, setInputAType] = useState("ERC20");
  const handChangeA = (val: string) => {
    setInputAType(val);
    val === "ETH"
      ? setTokenA("0x0000000000000000000000000000000000000000")
      : null;
  };
  const [inputBType, setInputBType] = useState("ERC20");
  const handChangeB = (val: string) => {
    setInputBType(val);
    val === "ETH"
      ? setTokenB("0x0000000000000000000000000000000000000000")
      : null;
  };

  const onFinish = async () => {
    setFormState(0);
    if (inputAType === "ETH") {
      setTokenA("0x0000000000000000000000000000000000000000");
    }
    if (inputBType === "ETH") {
      setTokenB("0x0000000000000000000000000000000000000000");
    }
    if (tokenA === tokenB || tokenA.length !== 42 || tokenB.length !== 42) {
      alert("地址相同或者地址不合理");
      return;
    }
    let res = (await getPoolInfo()).toString();
    if (res === "true") {
      setFormState(2);
    } else {
      setFormState(1);
    }
  };
  return (
    <div>
      {layout}
      {loading}
      <Row>
        <Col style={{ marginTop: "6%" }} span={7} offset={3}>
          <Form size="large">
            <Form.Item label="TokenA">
              <Form.Item
                noStyle
                rules={[{ required: true, message: "代币类型必须要选择" }]}
              >
                <Select
                  style={{ width: 100 }}
                  onChange={handChangeA}
                  disabled={inputBType === "ETH"}
                  defaultValue="ERC20"
                >
                  <Option value="ERC20">ERC20</Option>
                  <Option value="ETH">ETH</Option>
                </Select>
              </Form.Item>
              <br />
              <br />
              <Form.Item noStyle>
                <Input
                  style={{ width: "70%", height: "70px" }}
                  onChange={(e) => {
                    setTokenA(e.target.value);
                  }}
                  placeholder={
                    inputAType === "ETH" ? "选择ETH时不可输入" : "输入Token地址"
                  }
                  disabled={inputAType === "ETH"}
                />
              </Form.Item>
            </Form.Item>

            <Form.Item label="TokenB">
              <Form.Item
                noStyle
                rules={[{ required: true, message: "代币类型必须要选择" }]}
              >
                <Select
                  style={{ width: 100 }}
                  onChange={handChangeB}
                  disabled={inputAType === "ETH"}
                  defaultValue="ERC20"
                >
                  <Option value="ERC20">ERC20</Option>
                  <Option value="ETH">ETH</Option>
                </Select>
              </Form.Item>
              <br />
              <br />
              <Form.Item noStyle>
                <Input
                  style={{ width: "70%", height: "70px" }}
                  onChange={(e) => {
                    setTokenB(e.target.value);
                  }}
                  placeholder={
                    inputBType === "ETH" ? "选择ETH时不可输入" : "输入Token地址"
                  }
                  disabled={inputBType === "ETH"}
                />
              </Form.Item>
            </Form.Item>

            <Form.Item label=" " colon={false}>
              <Button
                style={{ width: 200, marginLeft: "10%", marginTop: "6%" }}
                size="large"
                type="primary"
                htmlType="submit"
                onClick={onFinish}
              >
                查看流动池
              </Button>
            </Form.Item>
          </Form>
        </Col>
        <Col span={2}>
          <RightCircleTwoTone
            style={{ marginTop: "200px", fontSize: "70px" }}
          />
        </Col>
        <Col span={8}>
          {formState === 2 ? (
            <PoolInfo />
          ) : (
            <p
              style={{
                marginTop: "30%",
                fontSize: "40px",
                fontFamily: "方正舒体",
                color: "skyblue",
              }}
            >
              {loadingMessage}
            </p>
          )}
        </Col>
      </Row>
    </div>
  );
};

export default PoolForm;
