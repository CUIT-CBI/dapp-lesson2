// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FT.sol";


contract uniswap is FT {


    address public token0;
    address public token1;

    uint256 private reserve0;
    uint256 private reserve1;


    
    constructor(address _token0,address _token1)FT("Y","ZHY"){
        token0 = _token0;
        token1 = _token1;
    }

//增加流动性
    function addLiquidity(uint256 amount0,uint256 amount1) public {
        (reserve0,reserve1) = getReserve();
        uint256 liquidity;

      
        IERC20 token0= IERC20(token0);
        IERC20 token1= IERC20(token1);

         
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        liquidity = amount0 * amount1;

        _mint(msg.sender, liquidity);
 
    }

    function removeLiquidity(uint256 liquidity) public {
    (reserve0,reserve1) = getReserve();
        
        require(liquidity>0,"invalid");
        assert(transfer(address(this), liquidity));
        


        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));

        uint amount0 = liquidity * reserve0 / totalSupply(); 
        uint amount1 = liquidity * reserve1 / totalSupply();

        _burn(msg.sender, liquidity);

        assert(IERC20(token0).transfer(msg.sender, amount0)); 
        assert(IERC20(token1).transfer(msg.sender, amount1));

        
    }


    function swap0(uint256 amountIn) public returns(uint256){
        uint ServicePrice = amountIn * 3/1000;
        uint256 amountOut0 = getAmountOut(amountIn - ServicePrice,token0);
        
        uint minTokens = amountOut0-amountOut0*CaculateToken1Slippage(amountOut0);
        require(amountOut0>=minTokens,"insuffcient output");
        IERC20(token0).transferFrom(msg.sender, address(this), amountOut0);
        this.transfer(msg.sender, amountOut0);
        return amountOut0;
    }
    
    function swap1(uint256 amountIn) public returns(uint256){
        uint ServicePrice = amountIn * 3/1000;
        uint256 amountOut1 = getAmountOut(amountIn - ServicePrice,token1);
        
        uint minTokens = amountOut1-amountOut1*CaculateToken1Slippage(amountOut1);
        require(amountOut1>=minTokens,"insuffcient output");
        IERC20(token1).transferFrom(msg.sender, address(this), amountOut1);
        this.transfer(msg.sender, amountOut1);
        return amountOut1;
    }


    function getReserve() public view returns (uint256,uint256){
        return (IERC20(token0).balanceOf(address(this)),IERC20(token1).balanceOf(address(this)));
    }

    function getAmountOut(uint256 amountIn,address fromToken) private view returns(uint256){
        require( reserve0 > 0&&reserve1 > 0,"invalid reserves");
        uint256 k = reserve0 * reserve1;
        uint256 amountOut;
        if(fromToken == token0){
            uint256 newReserve0 = reserve0 + amountIn;
            uint256 newReserve1 = k / newReserve0;
            amountOut = reserve1 - newReserve1;
        }else if(fromToken == token1){
            uint256 newReserve1 = reserve1 + amountIn;
            uint256 newReserve0 = k / newReserve1;
            amountOut = reserve0 - newReserve0;
        }
        return  amountOut;
  }

    //滑点计算
    function CaculateToken0Slippage(uint256 amountOut0)public view returns(uint256){
        uint256 token1Reserve;
        uint256 token2Reserve;
        (token1Reserve,token2Reserve) = getReserve();
        return  amountOut0/(token1Reserve+amountOut0);
     }
    function CaculateToken1Slippage(uint256 amountOut1)public view returns(uint256){
        uint256 token1Reserve;
        uint256 token2Reserve;
        (token1Reserve,token2Reserve) = getReserve();
        return  amountOut1/(token2Reserve+amountOut1);
  }


}
