// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./Math.sol";
/* 
    已完成：
    1.增加移出流动性
    2.交易功能
    3.手续费
    4.滑点
    5.部署脚本
    */
contract tokenPair {
    //存储代码地址
    address public token1;
    address public token2;
    //存储代码量
    uint256 token1Bal;
    uint256 token2Bal;
    //lptoken总量
    uint256 public totalLiquidity;
    mapping(address => uint256)public LPtoken;



//增加流动性
    function addLiquidity(address _token,uint _amount) external  {
        require(_amount!=0,"ZERO_ERROR");
        require(_token == token1|| _token == token2,"INVALID");
        //增加代币量
        uint amount0;
        uint amount1;

        if(_token == token1){
            amount0 = _amount;
            amount1 = token2Bal*amount0/token1Bal;
        }else{
            amount1 = _amount;
            amount0 = token1Bal*amount1/token2Bal;
        }

        ERC20(token1).transferFrom(msg.sender,address(this),amount0);
        ERC20(token2).transferFrom(msg.sender,address(this),amount1);

        //计算流动性
        uint liquidity = Math.min(amount0*(FT(token2).totalSupply()) / token1Bal, amount1*(FT(token1).totalSupply()) / token2Bal);
        FT(_token).mint(msg.sender,liquidity);

        token1Bal = ERC20(token1).balanceOf(address(this));
        token2Bal = ERC20(token2).balanceOf(address(this));
    }
    //移除流动性
    function withdrawLiquidity() public {
        uint256 LPAmount = LPtoken[msg.sender];
        require(LPAmount > 0);
        uint256 token1Amount = (LPAmount * token1Bal) / totalLiquidity;
        uint256 token2Amount = (LPAmount * token2Bal) / totalLiquidity;
        LPtoken[msg.sender]=0;
        totalLiquidity-=LPAmount;
        token1Bal-=token1Amount;
        token2Bal-=token2Amount;
        require(IERC20(token1).transfer(msg.sender, token1Amount));
        require(IERC20(token2).transfer(msg.sender, token2Amount));
    }

    function getAmount(uint256 inputAmount,uint256 inputBal,uint256 outputBal) 
    private 
    pure 
    returns (uint256) 
    {
        //0.3%的手续费
        uint256 fee = inputAmount * 997;
        uint256 numerator = fee * outputBal;
        uint256 denominator = (inputBal * 1000) + fee;

        return numerator / denominator;
    }

    //交换token1到token2+滑点
    function token0Swaptoken1(uint amountIn,uint minAmount) public {
        require(amountIn>0,"SWAP_ERROR");

        uint amountOut = getAmount(amountIn,token2Bal,token1Bal);
        require(amountOut>minAmount,"Must More Than Minamount!");

        //输入
        ERC20(token1).transferFrom(msg.sender,address(this),amountIn);
        //输出
        ERC20(token2).transfer(msg.sender,amountOut);

        token1Bal = ERC20(token1).balanceOf(address(this));
        token2Bal = ERC20(token2).balanceOf(address(this));
    }
    //交换token2到token1+滑点
    function token1Swaptoken0(uint amountIn,uint minAmount) public {
        require(amountIn>0,"SWAP_ERROR");
        uint amountOut = getAmount(amountIn,token1Bal,token2Bal);
        require(amountOut>minAmount,"Must More Than Minamount!");
        ERC20(token2).transferFrom(msg.sender,address(this),amountIn);
        //输出
        ERC20(token1).transfer(msg.sender,amountOut);

        token1Bal = ERC20(token1).balanceOf(address(this));
        token2Bal = ERC20(token2).balanceOf(address(this));
    }

}