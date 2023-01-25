pragma solidity >=0.5.0;

//用于pair合约的swap方法中

interface IMyDexCallee {
    function myDexCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
