// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FT.sol";

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract Pair is FT{
    
    uint public MINIMUM_LIQUIDITY = 10**3;
    address public token0;
    address public token1;
    //token0在交易池中的储备量
    uint112 public reserve0;
    uint112 public reserve1;
    uint256 public _totalSupply;
    
    
    constructor(address _token0, address _token1) FT("lptoken","lp") {
        token0 = _token0;
        token1 = _token1;
    }
    
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
    function totalsupply() public {

    }
  

    //增加流动性
    function add_liquidity(uint amount0, uint amount1, address to) external returns(uint liquidity) {
       require(to != token0 && to != token1, 'to is wrong');
       (uint112 _reserve0, uint112 _reserve1) = getReserves();
       ERC20(token0).transferFrom(msg.sender,address(this),amount0);
       ERC20(token1).transferFrom(msg.sender,address(this),amount1);
      
       uint256 currentSupply = super.totalSupply();
       uint256 reserveAfter0 = _reserve0 + amount0;
       uint256 reserveAfter1 = _reserve1 + amount1;
    
       if(currentSupply == 0 ){
           liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
           _mint(msg.sender,liquidity);
       }else{
           uint liquidity0 = reserveAfter0 * currentSupply / _reserve0;
           uint liquidity1 = reserveAfter1 * currentSupply / _reserve1;
           liquidity = Math.min(liquidity0,liquidity1);
        }
        super._mint(to,liquidity);
        _totalSupply += liquidity;
       
        reserve0 = uint112(reserveAfter0);
        reserve1 = uint112(reserveAfter1);
        
    }
    //移除流动性
   function remove_liquidity(uint liquidity) public returns(uint amount0, uint amount1){
       (uint112 _reserve0, uint _reserve1) = getReserves();
        uint currentSupply = _totalSupply;

        amount0 = liquidity * _reserve0 / currentSupply;
        amount1 = liquidity * _reserve1 / currentSupply;
        //销毁ft代币
        super._burn(msg.sender,liquidity);
        _totalSupply -= liquidity;

        ERC20(token0).transfer(msg.sender,amount0);
        ERC20(token1).transfer(msg.sender,amount1);

        uint256 balance0 = ERC20(token0).balanceOf(address(this));
        uint256 balance1 = ERC20(token1).balanceOf(address(this));
        //还原交易池里面原本代币储备量
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
    }

    function getAmount(uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut) private pure returns (uint256 amountOut) {
        amountOut = (reserveIn * reserveOut) / (reserveIn + amountIn);
        return amountOut;
    }
    
    //交易
    function TX(
        uint amount0In, 
        uint amount1In, 
        uint amountMin,
        address fromToken, 
        address toToken, 
        address to) external{
            require(to != fromToken && to != toToken, 'Ft: INVALID_TO');
            (uint112 _reserve0, uint112 _reserve1) = getReserves();
            //判断用于兑换的货币
            if(amount0In > 0) ERC20(fromToken).transferFrom(msg.sender, address(this), amount0In);
            if(amount1In > 0) ERC20(fromToken).transferFrom(msg.sender, address(this), amount1In);
            uint balance0 = ERC20(token0).balanceOf(address(this));
            uint balance1 = ERC20(token1).balanceOf(address(this));
            //扣除手续费
            uint amount0Out = getAmount(amount0In,_reserve0,_reserve1) * 997 /1000;
            uint amount1Out = getAmount(amount1In,_reserve1,_reserve0) * 997 /1000;
            //设置滑点
            if(amount0Out > 0) {
                require(amount0Out >= amountMin,'no more than amountIn');
                ERC20(toToken).transferFrom(msg.sender,to,amount0Out);
            }
            if(amount1Out > 0) {
                require(amount1Out >= amountMin,'no more than amountMin');
                ERC20(toToken).transferFrom(msg.sender,to,amount1Out);
            }
            reserve0 = uint112(balance0);
            reserve1 = uint112(balance1);
        }
    
}
