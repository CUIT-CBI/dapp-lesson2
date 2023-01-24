pragma solidity ^0.8.0;
import "./FT.sol";

//math
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
/* 区块链203毛浩昕2020131128
    1.增加移出流动性
    2.交易功能
    3.手续费
    4.滑点
    5.部署脚本
    */
contract TwoTokens{
    IERC20 public token1;
    IERC20 public token2;
    FT public ft;
    constructor(address _token1,address _token2,FT _ft){
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
        ft=_ft;
    }
    uint public totalA = 0;
    uint public totalB = 0;
    uint public MHX = 0;
    uint public liquidity = 0;
    uint public k = 0;
    
    ////增加流动性
    function addLiquidity(uint addamountA,uint addamountB) external{

        if (MHX==0) {
            token1.transferFrom(msg.sender, address(this), addamountA);
            token2.transferFrom(msg.sender, address(this), addamountB);
            totalA += addamountA;
            totalB += addamountB;
            MHX += Math.sqrt(totalA*totalB);
            liquidity =MHX;
            k = totalA*totalB;
            ft.mint(msg.sender, MHX);
        } else {
            uint256 transfertoken2Amount = (addamountA+totalA)*totalB/totalA;
            require(transfertoken2Amount==addamountB , "This is not the first time to top up, please top up according to the proportion");
            tokenZyh1.transferFrom(msg.sender, address(this), addamountA);
            tokenZyh2.transferFrom(msg.sender, address(this), addamountB);
            totalA += addamountA;
            totalB += addamountB;
            k = totalA*totalB;
            liquidity = Math.sqrt(totalA*totalB);
            MHX += Math.sqrt(addamountA*addamountB);
            ft.mint(msg.sender, Math.sqrt(addamountA*addamountB));
        }
    }

    function removeLiquidity(uint removetoken1Amount,uint _removetoken2Amount) external {
        uint removetoken2Amount =totalB - k/(totalA-removetoken1Amount);
        require(removetoken2Amount== _removetoken2Amount, " please top up according to the proportion");
        ft.burn(Math.sqrt(removetoken1Amount*removetoken2Amount));
        MHX -= Math.sqrt(removetoken1Amount*removetoken2Amount);
        totalA-=removetoken1Amount;
        totalB-=removetoken2Amount;
        k = totalA*totalB;
        //返还两种币
        token1.transfer(msg.sender, removetoken1Amount);
        token2.transfer(msg.sender, removetoken2Amount);
    }

    function gettoken2OutAmount(uint amountA) public view returns(uint) {
          uint token2OutAmount = totalB-(totalA+amountA)/k;
          return token2OutAmount;
    }
    function gettoken1OutAmount(uint amountB) public view returns(uint) {
          uint token1OutAmount = totalA-(totalB+amountB)/k;
          return token1OutAmount;
    }
    function ReplaceAwithB(uint amountInputA) external {
        uint token2OutAmount = gettoken2OutAmount(amountInputA);
        token2OutAmount = token2OutAmount *997/1000;
        if(token2OutAmount>=token2OutAmount*7/10){
            revert("Too little in return");
        }
        tokenZyh1.transferFrom(msg.sender, address(this),amountInputA);
        tokenZyh2.transfer(msg.sender,token2OutAmount);
        totalA+=amountInputA;
        totalB-=token2OutAmount;
    }
    function ReplaceBwithA(uint amountInputB) external {
        uint token1OutAmount = gettoken1OutAmount(amountInputB);
        token1OutAmount = token1OutAmount *997/1000;
        //滑点Zyh2
        if(token1OutAmount>=token1OutAmount*7/10){
            revert("Too little in return");
        }
        token2.transferFrom(msg.sender, address(this),amountInputB);
        token1.transfer(msg.sender,token1OutAmount);
        totalB+=amountInputB;
        totalA-=token1OutAmount;
    }


}
