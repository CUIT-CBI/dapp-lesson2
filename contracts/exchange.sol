// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./Math.sol";
import "./FT.sol";
contract woTokens{
    FT public ft;
    IERC20 public tokenD;
    IERC20 public tokenN;
    constructor(address _tokenD,address _tokenN,FT _ft){
        tokenD = IERC20(_tokenD);
        tokenN = IERC20(_tokenN);
        ft=_ft;
    }
    uint public totalD = 0;
    uint public totalN = 0;
    //LPtoken记录发送LPtoken总量
    uint public LPtoken = 0;
    uint public liquidity = 0;
    uint public k = 0;
    //添加流动性
    function addLiquidity(uint addnumberD,uint addnumberN) external{
        if (LPtoken==0) {
            tokenD.transferFrom(msg.sender, address(this), addnumberD);
            tokenN.transferFrom(msg.sender, address(this), addnumberN);
            totalD += addamountD;
            totalN += addamountN;
            LPtoken += Math.sqrt(totalD*totalN);
            liquidity = LPtoken;
            k = totalD*totalN;
            ft.mint(msg.sender, LPtoken);
            ft.mint(msg.sender, Math.sqrt(totalD*totalN));
        } else {
            uint256 transferTokenNAmount = (addnumberD+totalD)*totalN/totalD;
            require(transferTokenNAmount==addnumberN , "这不是第一次充值，请按比例充值");
            tokenD.transferFrom(msg.sender, address(this), addnumberD);
            tokenN.transferFrom(msg.sender, address(this), addnumberN);
            totalD += addnumberD;
            totalN += addnumberN;
            k = totalD*totalN;
            //D和N币的变化导致流动性变化
            liquidity = Math.sqrt(totalD*totalN);
            LPtoken += Math.sqrt(addnumberD*addnumberN);
            ft.mint(msg.sender, Math.sqrt(addnumberD*addnumberN));
        }
    }

    function removeLiquidity(uint removeTokenDnumber,uint _removeTokenNnumber) external {
        uint removeTokenNnumber =totalN - k/(totalD-removeTokenDnumber);
        require(removeTokenNnumber== _removeTokenNnumber, " 请按比例充值");
        //销毁LPtoken
        ft.burn(Math.sqrt(removeTokenDnumber*removeTokenNnumber));
        LPtoken -= Math.sqrt(removeTokenDnumber*removeTokenNnumber);
        totalD-=removeTokenDnumber;
        totalN-=removeTokenNnumber;
        k = totalD*totalN;
        //返还
        tokenD.transfer(msg.sender, removeTokenDnumber);
        tokenN.transfer(msg.sender, removeTokenNnumber);
    }

    function gettokenNOutnumber(uint amountD) public view returns(uint) {
          uint tokenNOutnumber = totalN-(totalD+amountD)/k;
          return tokenNOutnumber;
    }

    function substitute(uint amountInputN) external {
        uint tokenDOutnumber = gettokenDOutnumber(amountInputN);
        tokenDOutnumber = tokenDOutnumber *997/1000;
        if(tokenDOutnumber>=tokenDOutnumber*7/10){
            revert("回报太少");
        }
        tokenN.transferFrom(msg.sender, address(this),amountInputN);
        tokenD.transfer(msg.sender,tokenDOutnumber);
        totalN+=amountInputN;
        totalD-=tokenDOutnumber;
        k = totalD*totalN;
    }


}