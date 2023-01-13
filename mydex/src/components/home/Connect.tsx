import React, { useContext } from "react";
import { ConnectContext } from "../../context/ConnectContext";
import { Button } from "antd";

const Connect = () => {
  //  @ts-ignore
  const { currentAccount, connectWallet } = useContext(ConnectContext);
  return (
    <>
      {!currentAccount ? (
        <div
          style={{ textAlign: "center", padding: "30px", marginTop: "20px" }}
        >
          <p style={{ fontSize: "20px" }}>当前未连接任何账户,点击按钮连接</p>
          <Button
            size="large"
            type="primary"
            style={{ margin: "30px" }}
            onClick={() => connectWallet()}
          >
            连接
          </Button>
        </div>
      ) : (
        <div style={{ textAlign: "center", marginTop: "20px" }}>
          <p style={{ fontSize: "20px" }}>
            当前连接账户:
            <br />
            <br />
            {currentAccount}
          </p>
        </div>
      )}
    </>
  );
};

export default Connect;
