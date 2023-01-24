pragma solidity ^0.8.0;

import './FT.sol';
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract funcRealize is FT {
    using SafeMath  for uint;
    address public tokenA;
    address public tokenB; 

    //uint public constant MINIMUM_LIQUIDITY = 10**3;
    constructor(string memory name, string memory symbol) FT(name, symbol) {}

    //增加流动性
    function addLiquidity(uint amountA,uint amountB) public returns(uint AP){
        uint balanceA = FT(tokenA).balanceOf(address(this));
        uint balanceB = FT(tokenB).balanceOf(address(this));
        tokenA.transferFrom(msg.sender,address(this),amountA);
        tokenB.transferFrom(msg.sender,address(this),amountB); 
        uint reserve = totalSupply();
        if(reserve == 0){
           AP = Math.sqrt(amountA.mul(amountB));
        }else{
            uint _reserveA = amountA.mul(reserve) / balanceA;
            uint _reserveB = amountB.mul(reserve) / balanceB;
            AP = Math.min(newSupplyGivenReserveA,newSupplyGivenReserveB);
        }
        require(AP > 0,"Less MINIMUMLP");
        _mint(msg.sender,AP);
        _update(balanceA, balanceB);
    }

    //移出流动性
    function removeLiquidity(address to) public returns(uint amountA,uint amountB){
        uint RP = balanceOf(msg.sender); 
        require(RP != 0);
        uint balanceA = FT(tokenA).balanceOf(address(this));
        uint balanceB = FT(tokenB).balanceOf(address(this));  
        amountA = RP.mul(balanceA) / reserve;
        amountB = RP.mul(balanceB) / reserve;
        uint reserve = totalSupply();
        require(amountA > 0 && amountB > 0);
         _burn(msg.sender,reserve);
        FT(tokenA).transfer(to,amountA);
        FT(tokenB).transfer(to,amountB);
        _update(balanceA, balanceB);
    }

  // 交易功能                            
  //  实现手续费功能，千分之三手续费          
  //  实现滑点功能                         

      function AtoB(uint256 amountA,uint256 amountB) public onlyOwner retruns(uint256){
        require(amountB < FT(tokenB).balanceOf(address(this)));
        if( amountA > amountB){
           amountB =  amountA / AP;
        }else{amountB =  amountA * AP;
        }
        _amountA -=  amountA;
        _amountB +=  amountB;
        Liquidity =  _amountA *  _amountB;
        uint256 cost = amountA * (3/1000);
        uint256 k = amountA / amountB;
        FT(tokenA).transferFrom(msg.sender,address(this),amountA);
        FT(tokenB).transfer(msg.sender,amountB - cost);
        FT(tokenB).transfer(owner,cost);
        return amountB - cost;
    }

      function BtoA(uint256 amountA,uint256 amountB) public onlyOwner retruns(uint256){
        require(amountA < FT(tokenA).balanceOf(address(this)));
        if(amountA >  amountB){
            amountA =  amountB * G;
        }else{
            amountA =  amountB / G;
        }
        _amountA += amountA;
        _amountB -= amountB;
         Liquidity = _amountA * _amountB;
         uint256 cost = amountA * (3/1000);
         uint256 k = amountA / amountB;
        FT(tokenA).transfer(msg.sender,amountA - cost);
        FT(tokenA).transfer(owner,cost);
        FT(tokenB).transferFrom(msg.sender,address(this), amountB);
        return amountA - cost;
    }
}