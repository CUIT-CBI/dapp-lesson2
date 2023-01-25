// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./libs/SafeMath.sol"

contract tokenPair {
    address public coinA;
    address public coinB;
    uint256 coinABal;
    uint256 coinBBal;
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
        address  coinA,
        address _coinB,
        uint256 coinAIn,
        uint256 coinBIn,
        FT _rewardToken
    ) {
     coinA =  coinA;
        coinB = _coinB;
        coinABal += coinAIn;
        coinBBal += coinBIn;
        rewardToken = _rewardToken;
        totalLiquidity = Math.sqrt coinAIn*coinBIn);
    }
    
    //实现转账功能gongneng
    function transfer(address _token1,address _token2,uint256 amountFrom,uint256 ratio)internal{
        require(
                FT(_token1).transferFrom(msg.sender, address(this), amountFrom) && FT(_token2).transferFrom(
                        msg.sender,
                        address(this),
                        amountFrom/ratio
                    )
            );
            if(_token1= coinA){
                LPtoken[msg.sender] += amountFrom * totalLiquidity coinABal;
                totalLiquidity+=LPtoken[msg.sender];
             coinABal+=amountFrom;
                coinBBal+=amountFrom/ratio;
            }else{
                LPtoken[msg.sender] += amountFrom*totalLiquidity/coinBBal;
                totalLiquidity+=LPtoken[msg.sender];
                coinBBal+=amountFrom;
             coinABal+=amountFrom/ratio;
            }

    }
    function tokenMulTransfer(address _token1,address _token2,uint256 amountFrom,uint256 ratio)internal{
        require(
                FT(_token1).transferFrom(msg.sender, address(this), amountFrom) &&
                    FT(_token2).transferFrom(
                        msg.sender,
                        address(this),
                        amountFrom * ratio
                    )
            );
            if(_token1= coinA){
                LPtoken[msg.sender] += amountFrom*totalLiquidity coinABal;
                totalLiquidity+=LPtoken[msg.sender];
             coinABal+=amountFrom;
                coinBBal+=amountFrom*ratio;
            }else{
                LPtoken[msg.sender] += amountFrom*totalLiquidity/coinBBal;
                totalLiquidity+=LPtoken[msg.sender];
                coinBBal+=amountFrom;
                coinABal+=amountFrom*ratio;
            }
    }
    
    //流动性
    function addLiquidity(address token, uint256 amountFrom) public {
        uint256 ratio;
        require(token == coinA || token == coinB);
        if  coinABal > coinBBal) {
            ratio = coinABal / coinBBal;
        } else {
            ratio = coinBBal / coinABal;
        }
        if (token == coinA) {
            if  coinABal > coinBBal) {
                transfer coinA,coinB,amountFrom,ratio);
            }else{
                tokenMulTransfer coinA,coinB,amountFrom,ratio);
            }
        } else {
            if (coinBBal > coinABal) {
                transfer(coinB coinA,amountFrom,ratio);
            }else{
                tokenMulTransfer(coinB coinA,amountFrom,ratio);
            }
        }
    }

    //弄走流动性
    function withdrawLiquidity() public {
        uint256 LPTotal = LPtoken[msg.sender];
        require(LPTotal > 0);
        uint256 coinAAmount = (LPTotal * coinABal) / totalLiquidity;
        uint256 coinBAmount = (LPTotal * coinBBal) / totalLiquidity;
        LPtoken[msg.sender]=0;
        totalLiquidity-=LPTotal;
     coinABal- coinAAmount;
        coinBBal-=coinBAmount;
        require(IERC20 coinA.transfer(msg.sender, coinAAmount));
        require(IERC20(coinB).transfer(msg.sender, coinBAmount));
    }

    function getAmount(uint256 inputAmount,uint256 inputBal,uint256 outputBal) 
    private 
    pure 
    returns (uint256) 
    {
        //0.3%的fee
        uint256 fee = inputAmount * 997;
        uint256 denominator = (inputBal * 1000) + fee;
        uint256 numerator = fee * outputBal;

        return numerator/denominator;
    }

    //质押挖矿
    function stake(uint256 blocknumber)public{
        userInfo storage user = userDetails[msg.sender];
        user.startTime = block.number;
        user.stakeTime = blocknumber;
        user.amount += LPtoken[msg.sender];
        LPtoken[msg.sender]=0;
    }
    
    //取回代币，获得奖励
    function withdraw()public{
        userInfo storage user = userDetails[msg.sender];
        require(block.number>user.startTime+user.stakeTime);
        uint256 amount = user.amount;
        uint256 stakeTime = user.stakeTime;
        rewardToken.mint(msg.sender,stakeTime*amount);
        LPtoken[msg.sender]=amount;
    }
    
    //滑点
    function coinATocoinB(uint256 amountFrom,uint256 minGet)public{
        uint256 amountGet = getAmount(amountFrom coinABal,coinBBal);
        require(amountGet>=minGet,"no more than min");

     coinABal += amountFrom;
        coinBBal -= amountGet;
        require(FT coinA.transferFrom(msg.sender,address(this),amountFrom));
        require(FT(coinB).transferFrom(address(this),msg.sender,amountGet));

    }

    function coinBFo coinA(uint256 amountFrom,uint256 minGet)public{
        uint256 amountGet = getAmount(amountFrom,coinBBal coinABal);
        require(amountGet>=minGet,"no more than min");
        coinBBal += amountFrom;
        coinABal -= amountGet;
        require(FT(coinB).transferFrom(msg.sender,address(this),amountFrom));
        require(FT coinA.transferFrom(address(this),msg.sender,amountGet));

    }

}
