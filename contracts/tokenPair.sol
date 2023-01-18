// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./tokenFactory.sol";


//引用数学公式库，方便计算
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }


    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
/* 
    已完成：
    1.增加移出流动性
    2.交易功能
    3.手续费
    4.滑点
    5.部署脚本
    加分项：
    2.质押挖矿
    */
contract tokenPair {
    address public token1;
    address public token0;
    uint256 token1Reverse;
    uint256 token0Reverse;
    uint256 public totalLiquidity;
    mapping(address => uint256)public LPtoken;
    FT public rewardToken;

    struct userInfo{
        uint amount;
        uint stakeTime;
        uint startTime;
    }
    mapping(address => userInfo)public userDetails;
    constructor(
        address _token0,
        address _token1,
        uint256 token1In,
        uint256 token0In,
        FT _rewardToken
    ) {
        token0 = _token0;
        token1 = _token1;
        token0Reverse += token0In;
        token1Reverse += token1In;
        rewardToken = _rewardToken;
        totalLiquidity = Math.sqrt(token0In*token1In);
    }

    function tokenDivTransfer(address _tokenA,address _tokenB,uint256 amountIn,uint256 ratio)internal{
        require(
                FT(_tokenA).transferFrom(msg.sender, address(this), amountIn) &&
                    FT(_tokenB).transferFrom(
                        msg.sender,
                        address(this),
                        amountIn / ratio
                    )
            );
            if(_tokenA==token1){
                LPtoken[msg.sender] += amountIn*totalLiquidity/token1Reverse;
                totalLiquidity+=LPtoken[msg.sender];
                token0Reverse+=amountIn;
                token1Reverse+=amountIn/ratio;
            }else{
                LPtoken[msg.sender] += amountIn*totalLiquidity/token1Reverse;
                totalLiquidity+=LPtoken[msg.sender];
                token1Reverse+=amountIn;
                token0Reverse+=amountIn/ratio;
            }

    }
    function tokenMulTransfer(address _tokenA,address _tokenB,uint256 amountIn,uint256 ratio)internal{
        require(
                FT(_tokenA).transferFrom(msg.sender, address(this), amountIn) &&
                    FT(_tokenB).transferFrom(
                        msg.sender,
                        address(this),
                        amountIn * ratio
                    )
            );
            if(_tokenA==token0){
                LPtoken[msg.sender] += amountIn*totalLiquidity/token0Reverse;
                totalLiquidity+=LPtoken[msg.sender];
                token0Reverse+=amountIn;
                token1Reverse+=amountIn*ratio;
            }else{
                LPtoken[msg.sender] += amountIn*totalLiquidity/token1Reverse;
                totalLiquidity+=LPtoken[msg.sender];
                token1Reverse+=amountIn;
                token0Reverse+=amountIn*ratio;
            }
    }
    
    //增加流动性
    function addLiquidity(address token, uint256 amountIn) external payable {
        uint256 ratio;
        require(token == token0 || token == token1,"Incorrect address");
        if (token0Reverse > token1Reverse) {
            ratio = token0Reverse / token1Reverse;
        } else {
            ratio = token1Reverse / token0Reverse;
        }
        if (token == token1) {
            if (token1Reverse > token0Reverse) {
                tokenDivTransfer(token1,token0,amountIn,ratio);
            }else{
                tokenMulTransfer(token1,token0,amountIn,ratio);
            }
        } else {
            if (token0Reverse> token1Reverse) {
                tokenDivTransfer(token0,token1,amountIn,ratio);
            }else{
                tokenMulTransfer(token0,token1,amountIn,ratio);
            }
        }
    }

    //移除流动性
    function withdrawLiquidity() public {
        uint256 LPAmount = LPtoken[msg.sender];
        require(LPAmount > 0, "_amount should be greater than zero");
        uint256 token0Amount = (LPAmount * token0Reverse) / totalLiquidity;

        uint256 token1Amount = (LPAmount * token1Reverse) / totalLiquidity;
        LPtoken[msg.sender]=0;
        totalLiquidity-=LPAmount;
        token0Reverse-=token0Amount;
        token1Reverse-=token1Amount;
        require(IERC20(token0).transfer(msg.sender, token0Amount));
        require(IERC20(token1).transfer(msg.sender, token1Amount));
    }
    //实现手续费功能，获取返回给用户的代币数量
    //这里设置手续费为0.3％
    function getAmount(uint256 inputAmount,uint256 inputReserve,uint256 outputReserve)private pure returns (uint256){
        
        uint256 fee = inputAmount * 997;
        uint256 numerator = fee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + fee;

        return numerator / denominator;
    }

    //交易+滑点
    //滑点是指预期交易价格和实际成交价格之间的差值百分比
    //token0交换token1
    function token0ForToken1(uint256 amountIn,uint256 minGet)public{
        uint256 amountGet = getAmount(amountIn,token0Reverse,token1Reverse);
        require(amountGet>=minGet,"Incorrect output amount");

        token0Reverse += amountIn;
        token1Reverse -= amountGet;
        require(FT(token0).transferFrom(msg.sender,address(this),amountIn));
        require(FT(token1).transferFrom(address(this),msg.sender,amountGet));

    }
    //token1交换token0
    function token1ForToken0(uint256 amountIn,uint256 minGet)public{
        uint256 amountGet = getAmount(amountIn,token1Reverse,token0Reverse);
        require(amountGet>=minGet,"Incorrect output amount");

        token1Reverse += amountIn;
        token0Reverse -= amountGet;
        require(FT(token1).transferFrom(msg.sender,address(this),amountIn));
        require(FT(token0).transferFrom(address(this),msg.sender,amountGet));

    }
    //质押挖矿
    function stake(uint256 blocknumber)public{
        userInfo storage user = userDetails[msg.sender];
        user.startTime = block.number;
        user.stakeTime = blocknumber;
        user.amount += LPtoken[msg.sender];
        LPtoken[msg.sender]=0;
    }
    //取回质押token并获得奖励代币
    function unstake()public{
        userInfo storage user = userDetails[msg.sender];
        require(block.number>user.startTime+user.stakeTime);
        uint256 amount = user.amount;
        uint256 stakeTime = user.stakeTime;
        rewardToken.mint(msg.sender,stakeTime*amount);
        LPtoken[msg.sender]=amount;
    }

}
