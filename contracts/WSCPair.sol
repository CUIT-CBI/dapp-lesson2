// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract WSCPair is ERC20 {


    IERC20 public token0;
    IERC20 public token1;


    constructor(address _token0, address _token1) ERC20("WSC pair","WSC"){
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);

    }

    function addLiquidity(uint amount0, uint amount1) public returns (uint liquidity) {
        (uint256 balance0,uint256 balance1)=getStatus();
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        uint _totalSupply = totalSupply();
        liquidity = Math.min(amount0 * _totalSupply / balance0, amount1 * _totalSupply / balance1);
        require(liquidity > 0, "liquidity less than zero");
        _mint(msg.sender, liquidity);

    }

    function removeLiquidity(uint liquidity)public  {
        uint _totalSupply = totalSupply();

        (uint256 balance0,uint256 balance1)=getStatus();
        uint amount0 = liquidity * _totalSupply / balance0;
        uint amount1 = liquidity * _totalSupply / balance1;
        _burn(msg.sender, liquidity);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        
    }


    function swap(IERC20 token,uint amount,uint maxSlippage) public returns(uint slippage){
        IERC20 from=token0;
        IERC20 to=token1;
        (uint256 fromBalance,uint256 toBalance)=getStatus();
        if (token==token1){
            IERC20 temp=from;
            from=to;
            to=temp;
        }else if (token!=token0){
            require(token==token0,"err token");
        }
        uint256 swapAmount = (toBalance - fromBalance * toBalance/ (fromBalance + toBalance)) * (1000-3) / 1000;
        uint256 targetAmount = toBalance * swapAmount / fromBalance;
        slippage = (targetAmount - swapAmount) * 100 / targetAmount;
        if(maxSlippage!=0){
            require(maxSlippage<=slippage,"slippage too large");
        }
        from.transferFrom(msg.sender, address(this), amount);
        token1.transfer(msg.sender, swapAmount);

        
    }



    function getStatus() public view returns(uint256 balance0,uint256 balance1){
        balance0 = token0.balanceOf(address(this));
        balance1 = token1.balanceOf(address(this));
    }

}