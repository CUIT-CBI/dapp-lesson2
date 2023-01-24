// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WZYERC20.sol";

contract WZYPair is WZYERC20 {

    event AddLiquidity(address user,uint256 amount0,uint256 amount1);
    event RemoveLiquidity(address user,uint256 amount0,uint256 amount1);
    event Swap(address user,address from,uint256 amount,uint256 slippage);

    IERC20 public token0;
    IERC20 public token1;
    
    // 用来设置百分比
    uint256 public  percentage;

    constructor(address _token0, address _token1,uint256 _percentage) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        percentage=_percentage;
    }

    function addLiquidity(uint amount0, uint amount1)  returns (uint liquidity) {
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        uint _totalSupply = totalSupply();
        liquidity = Math.min(amount0 * _totalSupply / reserveA, amount1 * _totalSupply / reserveB);
        require(liquidity > 0, "liquidity less than zero");
        _mint(msg.sender, liquidity);
        emit AddLiquidity(msg.sender,amount0,amount1);
    }

    function removeLiquidity(uint liquidity)  {
        uint _totalSupply = totalSupply();
        
        uint256 balance0,uint256 balance1=getStatus();
        uint amount0 = liquidity * _totalSupply / balance0;
        uint amount1 = liquidity * _totalSupply / balance1;
        _burn(msg.sender, liquidity);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        emit RemoveLiquidity(msg.sender,amount0,amount1);
    }

    // 交换   token 拥有的代币  amount 该代币用于交易的量   maxSlippage 最大可接受的滑点数（若填0则是强制交易 不在乎滑点 滑点为0本身就不存在）
    function swap(address token,uint amount,uint maxSlippage)returns(uint slippage){
        uint256 _percentage=percentage;
        IERC20 from=token0;
        IERC20 to=token1;
        uint256 fromBalance,uint256 toBalance=getStatus();
        if (token==token1){
            from,to=to,from;
            fromBalance,toBalance=toBalance,fromBalance;
        }else if (token!=token0){
            // 错误的token地址
            revert("error token address");
        }
        uint256 swapAmount = (toBalance - fromBalance * toBalance/ (fromBalance + toBalance)) * (1000-_percentage) / 1000;
        
        //计算滑点
        uint256 targetAmount = toBalance * swapAmount / fromBalance;
        slippage = (targetAmount - swapAmount) * 100 / targetAmount;
        if(maxSlippage!=0){
            // 滑点过大 回滚
            require(maxSlippage<=slippage,"slippage too large");
        }

        from.transferFrom(msg.sender, address(this), amount);
        token1.transfer(msg.sender, swapAmount);

        emit Swap(msg.sender,address(from),amount,slippage);
    }



    function getStatus() public view returns(uint256 balance0,uint256 balance1){
        balance0 = token0.balanceOf(address(this));
        balance1 = token1.balanceOf(address(this));
        return ;
    }

}