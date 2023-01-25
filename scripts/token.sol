  // SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract tokenExchange is FT{
    ERC20 tokenA;
    ERC20 tokenB;
    //
    uint256 public reserveA = 0;
    uint256 public reserveB = 0;

constructor(address addresstokenA,address addresstokenB)FT("liquidity","[~]"){
    tokenA=ERC20(addresstokenA);
    tokenB=ERC20(addresstokenB);
}
//增加流动性
function addLiquidity(uint256 amountA,uint256 amountB)external{
    //检查金额
    require(amountA*amountB>0,"invalid input");
    //检查是否approved
    require(tokenA.allowance(msg.sender,address(this))>=amountA && tokenB.allowance(msg.sender,address(this))>=amountB,"not approved");

    //初始状态添加流动性
    if (reserveA == 0) {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        reserveA+=amountA;
        reserveB+=amountB;
        //记录用户添加的流动性
        _mint(msg.sender,amountA);
    }
    else{
        //检查增加的A、B是否符合比例
        require(amountA/amountB==reserveA/reserveB,"Not in proportion");
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        reserveA+=amountA;
        reserveB+=amountB;
        //记录用户添加的流动性
        uint256 liquidity = (amountA * totalSupply()) / reserveA;
        _mint(msg.sender, liquidity);

    }
}

//移除流动性
function removeLiquidity(uint amountA) external {
        require(amountA > 0 && amountA<=(balanceOf(msg.sender)*reserveA)/totalSupply(), "invalid");
        uint amountB = (amountA*reserveB)/reserveA;
        //记录移除的流动性 
        _burn(msg.sender, amountA);
        reserveA-=amountA;
        reserveB-=amountB;
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }


//交易功能
function AtoB(uint256 buyAmountB)external{

    uint256 neededAmountA = reserveA*reserveB/(reserveB-buyAmountB)-reserveA;
    uint256 neededtoPayA=neededAmountA*1003/1000;//添加手续费
    //检查是否approved
    require(tokenA.allowance(msg.sender,address(this))>=neededtoPayA,"not approved");

    tokenA.transferFrom(msg.sender, address(this), neededtoPayA);
    tokenB.transfer(msg.sender,buyAmountB);
    reserveA+=neededtoPayA;
    reserveB-=buyAmountB;
}

function BtoA(uint256 buyAmountA)external{
    uint256 neededAmountB = reserveA*reserveB/(reserveA-buyAmountA)-reserveB;
    uint256 neededtoPayB=neededAmountB*1003/1000;//添加手续费
     //检查是否approved
    require(tokenB.allowance(msg.sender,address(this))>=neededtoPayB,"not approved");

    tokenB.transferFrom(msg.sender, address(this), neededtoPayB);
    tokenA.transfer(msg.sender,buyAmountA);
    reserveB+=neededtoPayB;
    reserveA-=buyAmountA;

}



}
