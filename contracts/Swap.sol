// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./Math.sol";
import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/*
已实现如下功能：
### 1. 增加/移出流动性                      30分
### 2. 交易功能                            30分
### 3. 实现手续费功能，千分之三手续费          10分
### 4. 实现滑点功能                         15分
### 5. 实现部署脚本                         15分
*/
contract Swap{
    IERC20 public tokenA;
    IERC20 public tokenB;
    FT public ft;
    constructor(address _tokenA,address _tokenB,FT _ft){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        ft=_ft;
    }
    uint public totalA = 0;
    uint public totalB = 0;
    //记录发送的LPtoken总量
    uint public LPtoken = 0;
    uint public liquidity = 0;
    uint public k = 0;
    function addLiquidity(uint addamountA,uint addamountB) external{
        if (LPtoken==0) {
            tokenA.transferFrom(msg.sender, address(this), addamountA);
            tokenB.transferFrom(msg.sender, address(this), addamountB);
            totalA += addamountA;
            totalB += addamountB;
            LPtoken += Math.sqrt(totalA*totalB);
            //流动性总量
            liquidity = LPtoken;
            k = totalA*totalB;
            ft.mint(msg.sender, Math.sqrt(totalA*totalB));
        } else {
            uint256 transferTokenBAmount = (addamountA+totalA)*totalB/totalA;
            require(transferTokenBAmount==addamountB);
            tokenA.transferFrom(msg.sender, address(this), addamountA);
            tokenB.transferFrom(msg.sender, address(this), addamountB);
            totalA += addamountA;
            totalB += addamountB;
            k = totalA*totalB;
            //流动性发生变化
            liquidity = Math.sqrt(totalA*totalB);
            LPtoken += Math.sqrt(addamountA*addamountB);
            ft.mint(msg.sender, Math.sqrt(addamountA*addamountB));
        }
    }

    function removeLiquidity(uint removeTokenAAmount,uint _removeTokenBAmount) external {
        uint removeTokenBAmount =totalB - k/(totalA-removeTokenAAmount);
        require(removeTokenBAmount== _removeTokenBAmount);
        //销毁LPtoken
        ft.burn(Math.sqrt(removeTokenAAmount*removeTokenBAmount));
        LPtoken -= Math.sqrt(removeTokenAAmount*removeTokenBAmount);
        totalA-=removeTokenAAmount;
        totalB-=removeTokenBAmount;
        //更新k
        k = totalA*totalB;
        tokenA.transfer(msg.sender, removeTokenAAmount);
        tokenB.transfer(msg.sender, removeTokenBAmount);
    }

    function gettokenBOutAmount(uint amountA) public view returns(uint) {
          uint tokenBOutAmount = totalB-(totalA+amountA)/k;
          return tokenBOutAmount;
    }
    function gettokenAOutAmount(uint amountB) public view returns(uint) {
          uint tokenAOutAmount = totalA-(totalB+amountB)/k;
          return tokenAOutAmount;
    }
    function ReplaceAwithB(uint amountInputA) external {
        uint tokenBOutAmount = gettokenBOutAmount(amountInputA);
        tokenBOutAmount = tokenBOutAmount *997/1000;
        //滑点
        if(tokenBOutAmount>=tokenBOutAmount*7/10){
            revert("Too little in return");
        }
        tokenA.transferFrom(msg.sender, address(this),amountInputA);
        tokenB.transfer(msg.sender,tokenBOutAmount);
        totalA+=amountInputA;
        totalB-=tokenBOutAmount;
        //更新k
        k = totalA*totalB;
    }
    function ReplaceBwithA(uint amountInputB) external {
        uint tokenAOutAmount = gettokenAOutAmount(amountInputB);
        tokenAOutAmount = tokenAOutAmount *997/1000;
        //滑点
        if(tokenAOutAmount>=tokenAOutAmount*7/10){
            revert("Too little in return");
        }
        tokenB.transferFrom(msg.sender, address(this),amountInputB);
        tokenA.transfer(msg.sender,tokenAOutAmount);
        totalB+=amountInputB;
        totalA-=tokenAOutAmount;
        k = totalA*totalB;
    }

    
}