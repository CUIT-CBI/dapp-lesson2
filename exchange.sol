// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./Math.sol";
import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract exchange{
    FT public ft;
    IERC20 public tokenA;
    IERC20 public tokenB;
    constructor(address _tokenA,address _tokenB,FT _ft){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        ft=_ft;
    }
    uint public totalA = 0;
    uint public totalB = 0;
    //LPtoken记录发送LPtoken总量
    uint public LPtoken = 0;
    uint public liquidity = 0;
    uint public k = 0;
    //添加流动性
    function addLiquidity(uint addnumberA,uint addnumberB) external{
        if (LPtoken==0) {
            tokenA.transferFrom(msg.sender, address(this), addnumberA);
            tokenB.transferFrom(msg.sender, address(this), addnumberB);
            totalA += addamountA;
            totalB += addamountB;
            LPtoken += Math.sqrt(totalA*totalB);
            liquidity = LPtoken;
            k = totalA*totalB;
            ft.mint(msg.sender, LPtoken);
            ft.mint(msg.sender, Math.sqrt(totalA*totalB));
        } else {
            uint256 transferTokenBAmount = (addnumberA+totalA)*totalB/totalA;
            require(transferTokenBAmount==addnumberB , "请按比例充值");
            tokenA.transferFrom(msg.sender, address(this), addnumberA);
            tokenB.transferFrom(msg.sender, address(this), addnumberB);
            totalA += addnumberA;
            totalB += addnumberB;
            k = totalA*totalB;
            liquidity = Math.sqrt(totalA*totalB);
            LPtoken += Math.sqrt(addnumberA*addnumberB);
            ft.mint(msg.sender, Math.sqrt(addnumberA*addnumberB));
        }
    }

    function removeLiquidity(uint removeTokenAnumber,uint _removeTokenBnumber) external {
        uint removeTokenBnumber =totalB - k/(totalA-removeTokenAnumber);
        require(removeTokenBnumber== _removeTokenBnumber, " 请按比例充值");
        //销毁
        ft.burn(Math.sqrt(removeTokenAnumber*removeTokenBnumber));
        LPtoken -= Math.sqrt(removeTokenAnumber*removeTokenBnumber);
        totalA-=removeTokenAnumber;
        totalB-=removeTokenBnumber;
        k = totalA*totalB;
        //返还
        tokenA.transfer(msg.sender, removeTokenAnumber);
        tokenB.transfer(msg.sender, removeTokenBnumber);
    }

    function gettokenBOutnumber(uint amountA) public view returns(uint) {
          uint tokenBOutnumber = totalB-(totalA+amountA)/k;
          return tokenBOutnumber;
    }
    function gettokenAOutnumber(uint amountB) public view returns(uint) {
          uint tokenAOutnumber = totalA-(totalB+amountB)/k;
          return tokenAOutnumber;
    }
    function substitute(uint amountInputA) external {
        uint tokenBOutnumber = gettokenBOutnumber(amountInputA);
        tokenBOutnumber = tokenBOutnumber *997/1000;
        //滑点
        if(tokenBOutnumber>=tokenBOutnumber*7/10){
            revert("回报太少");
        }
        tokenA.transferFrom(msg.sender, address(this),amountInputA);
        tokenB.transfer(msg.sender,tokenBOutnumber);
        totalA+=amountInputA;
        totalB-=tokenBOutnumber;
        k = totalA*totalB;
    }
    function substitute(uint amountInputB) external {
        uint tokenAOutnumber = gettokenAOutnumber(amountInputB);
        tokenAOutnumber = tokenAOutnumber *997/1000;
        if(tokenAOutnumber>=tokenAOutnumber*7/10){
            revert("回报太少");
        }
        tokenB.transferFrom(msg.sender, address(this),amountInputB);
        tokenA.transfer(msg.sender,tokenAOutnumber);
        totalB+=amountInputB;
        totalA-=tokenAOutnumber;
        k = totalA*totalB;
    }


}