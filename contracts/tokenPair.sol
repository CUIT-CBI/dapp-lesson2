// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Math.sol";

//实现全部功能 未实现附加题
contract TokenPair is ERC20 {
    

    IERC20 public token1;
    IERC20 public token2;
    


    constructor(address _token1, address _token2) ERC20("tokenPair","TP"){
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function addLiquidity(uint amount1, uint amount2)  public returns (uint liquidity) {
        (uint256 balance1,uint256 balance2)=getStatus();
        token1.transferFrom(msg.sender, address(this), amount1);
        token2.transferFrom(msg.sender, address(this), amount2);

        uint _totalSupply = totalSupply();
        
        liquidity = Math.min(amount1 * _totalSupply / balance1, amount2 * _totalSupply / balance2);
        require(liquidity > 0, "liquidity less than zero");
        _mint(msg.sender, liquidity);
    
    }

    function removeLiquidity(uint liquidity)  public {
        uint _totalSupply = totalSupply();
        
        (uint256 balance1,uint256 balance2)=getStatus();
        uint amount1 = liquidity * _totalSupply / balance1;
        uint amount2 = liquidity * _totalSupply / balance2;
        _burn(msg.sender, liquidity);

        token1.transfer(msg.sender, amount1);
        token2.transfer(msg.sender, amount2);

    
    }

    function swap(address token,uint amount,uint minSwapAmount) public {       
        require(token==address(token1) || token==address(token2),"error token address");
        (uint256 balance1,uint256 balance2)=getStatus();
        (IERC20 from,IERC20 to, uint256 fromBalance,uint256 toBalance)=token==address(token1)?(token1,token2,balance1,balance2):(token2,token1,balance2,balance1);
        uint256 swapAmount = (toBalance - fromBalance * toBalance/ (fromBalance + toBalance)) * (1000-3) / 1000;
        if(minSwapAmount!=0){
            require(swapAmount>minSwapAmount,"swap so low");
        }
        from.transferFrom(msg.sender, address(this), amount);
        token2.transfer(msg.sender, swapAmount);
    }



    function getStatus() public view returns(uint256 balance1,uint256 balance2){
        balance1 = token1.balanceOf(address(this));
        balance2 = token2.balanceOf(address(this));
    }

}