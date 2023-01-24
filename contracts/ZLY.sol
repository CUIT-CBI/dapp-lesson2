// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Math.sol"
import "./FT.sol";


contract ZLY is FT{

    uint public MINIMUM_LIQUIDITY = 10**3;
   
    address public Token1;
    address public Token2;
    address Factory;
    //两种token在交易池中的储备量
    uint112 public Reserve1;
    uint112 public Reserve2;


    constructor(address _Token1, address _Token2) FT("ZLYtoken","ZLY") {
        Token1 = _Token1;
        Token2 = _Token2;
    }

    function getReserves() public view returns (uint112 _Reserve1, uint112 _Reserve2) {
        _Reserve1 = Reserve1;
        _Reserve2 = Reserve2;
    }
        //交易
    function _exchange(
        uint amount1In, 
        uint amount2In, 
        uint amountMin,
        address fromToken, 
        address toToken, 
        address to) external{
            require(to != fromToken && to != toToken, 'Ft: INVALID_TO');
            (uint112 _reserve1, uint112 _reserve2) = getReserves();
            //判断哪个是用来兑换的货币
            if(amount1In > 0) ERC20(fromToken).transferFrom(msg.sender, address(this), amount1In);
            if(amount2In > 0) ERC20(fromToken).transferFrom(msg.sender, address(this), amount2In);
            //当前交易池里面还剩下多少token  
            uint balance1 = ERC20(token1).balanceOf(address(this));
            uint balance2 = ERC20(token2).balanceOf(address(this));
            //扣除手续费
            uint amount1Out = getAmount(amount1In,_reserve1,_reserve2) * (1-0.003);
            uint amount2Out = getAmount(amount2In,_reserve2,_reserve1) * (1-0.003);

    //赋予流动性
    function addliqiudity(uint amount1, uint amount2, address to) external returns(uint liquid) {
       require(to != token1 && to != token2, 'to io wrong');
       (uint112 _reserve1, uint112 _reserve2) = getReserves();
       //将token转入交易池储存
       ERC20(token1).transferFrom(msg.sender,address(this),amount1);
       ERC20(token2).transferFrom(msg.sender,address(this),amount2);

  
