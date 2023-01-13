import React, { useState } from "react";
import {
  ProfileFilled,
  BankFilled,
  DollarCircleFilled,
} from "@ant-design/icons";
import type { MenuProps } from "antd";
import { Menu } from "antd";
import { Col, Row } from "antd/lib/grid";
import { useNavigate } from "react-router-dom";


const items: MenuProps["items"] = [
  {
    label: "首页",
    key: "home",
    icon: <BankFilled style={{ fontSize: "25px", color: "skyblue" }} />,
  },
  {
    label: "流动池",
    key: "pool",
    icon: <ProfileFilled style={{ fontSize: "25px", color: "skyblue" }} />,
  },
  {
    label: "交换",
    key: "swap",
    icon: <DollarCircleFilled style={{ fontSize: "25px", color: "skyblue" }} />,
  },
];

const BaseLayout: React.FC = () => {
  const [current, setCurrent] = useState("home");
  const navigateTo = useNavigate();
  const menuClick = (e: { key: string }) => {
    navigateTo(e.key);
    setCurrent(e.key);
  };

  return (
    <Row style={{ marginTop: "20px" }}>
      <Col span={6}>
        <p
          style={{
            paddingLeft: "30px",
            fontFamily: "Broadway",
            fontSize: "60px",
            color: "grey",
          }}
        >
          My-Dex
        </p>
      </Col>
      <Col span={18}>
        <Menu
          style={{ paddingLeft: "500px", fontSize: "20px" }}
          onClick={menuClick}
          selectedKeys={[current]}
          mode="horizontal"
          items={items}
        />
      </Col>
    </Row>
  );
};

export default BaseLayout;
