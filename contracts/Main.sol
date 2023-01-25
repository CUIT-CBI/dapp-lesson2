// SPDX-License-Identifier: MIX
pragma solidity ^0.8.0;

import "./FT.sol";
import "./Math.sol";
import "./SafeMath.sol";
// import "./Factory.sol";

//一对一交易池
contract Main is FT{
    using Math for uint;
   
    address public token0;
    address public token1;
    uint public reserve0; 
    uint public reserve1;

    //交易对
    function createPair(uint _balance0,uint _balance1) public {
        require(_balance0!=0 && _balance1 != 0,"createPair_ERROR");
        ERC20(token0).transferFrom(msg.sender,address(this),_balance0);
        ERC20(token1).transferFrom(msg.sender,address(this),_balance1);
        
        uint liquidity = Math.sqrt(_balance0*_balance1);
        _mint(msg.sender,liquidity);

        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));
    }

    //增加流动性
    function addLiquidity(address _token,uint _amount) external {
        require(_amount!=0,"ZERO_ERROR");
        require(_token == token0 || _token == token1,"INVALID");
        
        uint amount0;
        uint amount1;

        if(_token == token0){
            amount0 = _amount;
            amount1 = reserve1*amount0/reserve0;
        }else{
            amount1 = _amount;
            amount0 = reserve0*amount1/reserve1;
        }

        ERC20(token0).transferFrom(msg.sender,address(this),amount0);
        ERC20(token1).transferFrom(msg.sender,address(this),amount1);

        //计算流动性
        uint liquidity = Math.min(SafeMath.mul(amount0,totalSupply()) / reserve0, SafeMath.mul(amount1,totalSupply()) / reserve1);
        _mint(msg.sender,liquidity);

        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));
    }

    //移除流动性
    function removeLiquidity(uint _amount) external{
        require(_amount>0,"REMOVE_ERROR");
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));

        uint sub0 = SafeMath.mul(balance0, _amount)/totalSupply();
        uint sub1 = SafeMath.mul(balance1, _amount)/totalSupply();

        _burn(msg.sender,_amount);

        ERC20(token0).transfer(msg.sender,sub0);
        ERC20(token1).transfer(msg.sender,sub1);

        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));
    }

    //实现手续费功能,得到输出值(k=xy)
    function getAmountOut(uint amountIn, uint _reserve0,uint _reserve1) internal pure returns(uint amountOut){
        // require()
        //手续费为千分之三
        uint x = _reserve0*amountIn*997;//分子
        uint y = _reserve1*1000+amountIn*997;//分母

        amountOut = x/y;
    }





}