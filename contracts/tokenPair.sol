// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";

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
    address public token2;
    uint256 token1Bal;
    uint256 token2Bal;
    uint256 public totalLiquidity;
    mapping(address => uint256)public LPtoken;
    FT public rewardToken;

    //用户质押信息
    struct userInfo{
        uint amount;
        uint stakeTime;
        uint startTime;
    }
    mapping(address => userInfo)public userDetails;
    constructor(
        address _token1,
        address _token2,
        uint256 token1In,
        uint256 token2In,
        FT _rewardToken
    ) {
        token1 = _token1;
        token2 = _token2;
        token1Bal += token1In;
        token2Bal += token2In;
        rewardToken = _rewardToken;
        totalLiquidity = Math.sqrt(token1In*token2In);
    }
    //功能转账函数
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
                LPtoken[msg.sender] += amountIn*totalLiquidity/token1Bal;
                totalLiquidity+=LPtoken[msg.sender];
                token1Bal+=amountIn;
                token2Bal+=amountIn/ratio;
            }else{
                LPtoken[msg.sender] += amountIn*totalLiquidity/token2Bal;
                totalLiquidity+=LPtoken[msg.sender];
                token2Bal+=amountIn;
                token1Bal+=amountIn/ratio;
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
            if(_tokenA==token1){
                LPtoken[msg.sender] += amountIn*totalLiquidity/token1Bal;
                totalLiquidity+=LPtoken[msg.sender];
                token1Bal+=amountIn;
                token2Bal+=amountIn*ratio;
            }else{
                LPtoken[msg.sender] += amountIn*totalLiquidity/token2Bal;
                totalLiquidity+=LPtoken[msg.sender];
                token2Bal+=amountIn;
                token1Bal+=amountIn*ratio;
            }
    }
    //增加流动性
    function addLiquidity(address token, uint256 amountIn) public {
        uint256 ratio;
        require(token == token1 || token == token2);
        if (token1Bal > token2Bal) {
            ratio = token1Bal / token2Bal;
        } else {
            ratio = token2Bal / token1Bal;
        }
        if (token == token1) {
            if (token1Bal > token2Bal) {
                tokenDivTransfer(token1,token2,amountIn,ratio);
            }else{
                tokenMulTransfer(token1,token2,amountIn,ratio);
            }
        } else {
            if (token2Bal > token1Bal) {
                tokenDivTransfer(token2,token1,amountIn,ratio);
            }else{
                tokenMulTransfer(token2,token1,amountIn,ratio);
            }
        }
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

    //交易+滑点
    //token1交换token2
    function token1ForToken2(uint256 amountIn,uint256 minGet)public{
        uint256 amountGet = getAmount(amountIn,token1Bal,token2Bal);
        require(amountGet>=minGet,"no more than min");

        token1Bal += amountIn;
        token2Bal -= amountGet;
        require(FT(token1).transferFrom(msg.sender,address(this),amountIn));
        require(FT(token2).transferFrom(address(this),msg.sender,amountGet));

    }
    //token2交换token1
    function token2ForToken1(uint256 amountIn,uint256 minGet)public{
        uint256 amountGet = getAmount(amountIn,token2Bal,token1Bal);
        require(amountGet>=minGet,"no more than min");

        token2Bal += amountIn;
        token1Bal -= amountGet;
        require(FT(token2).transferFrom(msg.sender,address(this),amountIn));
        require(FT(token1).transferFrom(address(this),msg.sender,amountGet));

    }
    //质押挖矿功能
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
