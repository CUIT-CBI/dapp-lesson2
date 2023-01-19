// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./Math.sol";
import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
区块链工程203周杨瀚2020131133
实现功能
1. 增加/移出流动性                      
2. 交易功能                            
3. 实现手续费功能，千分之三手续费          
4. 实现滑点功能                         
5. 实现部署脚本                         
*/
contract ExchangeTwoTokens{
    IERC20 public tokenZyh1;
    IERC20 public tokenZyh2;
    FT public ft;
    constructor(address _tokenZyh1,address _tokenZyh2,FT _ft){
        tokenZyh1 = IERC20(_tokenZyh1);
        tokenZyh2 = IERC20(_tokenZyh2);
        ft=_ft;
    }
    uint public totalA = 0;
    uint public totalB = 0;
    //以ZYH来记录发送的ZYH总量
    uint public ZYH = 0;
    uint public liquidity = 0;
    uint public k = 0;
    function addLiquidity(uint addamountA,uint addamountB) external{

        if (ZYH==0) {
            tokenZyh1.transferFrom(msg.sender, address(this), addamountA);
            tokenZyh2.transferFrom(msg.sender, address(this), addamountB);
            totalA += addamountA;
            totalB += addamountB;
            ZYH += Math.sqrt(totalA*totalB);
            liquidity = ZYH;
            k = totalA*totalB;
            ft.mint(msg.sender, ZYH);
        } else {
            uint256 transfertokenZyh2Amount = (addamountA+totalA)*totalB/totalA;
            require(transfertokenZyh2Amount==addamountB , "This is not the first time to top up, please top up according to the proportion");
            tokenZyh1.transferFrom(msg.sender, address(this), addamountA);
            tokenZyh2.transferFrom(msg.sender, address(this), addamountB);
            totalA += addamountA;
            totalB += addamountB;
            k = totalA*totalB;
            liquidity = Math.sqrt(totalA*totalB);
            ZYH += Math.sqrt(addamountA*addamountB);
            ft.mint(msg.sender, Math.sqrt(addamountA*addamountB));
        }
    }

    function removeLiquidity(uint removetokenZyh1Amount,uint _removetokenZyh2Amount) external {
        // require(removetokenZyh1Amount > 0 && removetokenZyh1Amount<=(balanceOf(msg.sender)*totalA)/totalSupply(), "invalid amount");
        uint removetokenZyh2Amount =totalB - k/(totalA-removetokenZyh1Amount);
        require(removetokenZyh2Amount== _removetokenZyh2Amount, " please top up according to the proportion");
        //销毁ZYH
        ft.burn(Math.sqrt(removetokenZyh1Amount*removetokenZyh2Amount));
        ZYH -= Math.sqrt(removetokenZyh1Amount*removetokenZyh2Amount);
        totalA-=removetokenZyh1Amount;
        totalB-=removetokenZyh2Amount;
        k = totalA*totalB;
        //返还两种币
        tokenZyh1.transfer(msg.sender, removetokenZyh1Amount);
        tokenZyh2.transfer(msg.sender, removetokenZyh2Amount);
    }

    function gettokenZyh2OutAmount(uint amountA) public view returns(uint) {
          uint tokenZyh2OutAmount = totalB-(totalA+amountA)/k;
          return tokenZyh2OutAmount;
    }
    function gettokenZyh1OutAmount(uint amountB) public view returns(uint) {
          uint tokenZyh1OutAmount = totalA-(totalB+amountB)/k;
          return tokenZyh1OutAmount;
    }
    function ReplaceAwithB(uint amountInputA) external {
        uint tokenZyh2OutAmount = gettokenZyh2OutAmount(amountInputA);
        tokenZyh2OutAmount = tokenZyh2OutAmount *997/1000;
        //滑点Zyh1
        if(tokenZyh2OutAmount>=tokenZyh2OutAmount*7/10){
            revert("Too little in return");
        }
        tokenZyh1.transferFrom(msg.sender, address(this),amountInputA);
        tokenZyh2.transfer(msg.sender,tokenZyh2OutAmount);
        totalA+=amountInputA;
        totalB-=tokenZyh2OutAmount;
    }
    function ReplaceBwithA(uint amountInputB) external {
        uint tokenZyh1OutAmount = gettokenZyh1OutAmount(amountInputB);
        tokenZyh1OutAmount = tokenZyh1OutAmount *997/1000;
        //滑点Zyh2
        if(tokenZyh1OutAmount>=tokenZyh1OutAmount*7/10){
            revert("Too little in return");
        }
        tokenZyh2.transferFrom(msg.sender, address(this),amountInputB);
        tokenZyh1.transfer(msg.sender,tokenZyh1OutAmount);
        totalB+=amountInputB;
        totalA-=tokenZyh1OutAmount;
    }


}