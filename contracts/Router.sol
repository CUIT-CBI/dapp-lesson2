// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
import "./DMSPair.sol";
import "../lib/Pair2.sol";


// 参考V2版本的uniswap 支持两种erc20之间的转换，池子
contract Router {
   Pair2 pair;
    constructor(address add) {
    pair = Pair2(add);//构建池子种的一对币种转换
    }

    function addLiq(address token1, address token2, uint256 amount1, uint256 amount2, uint256 amount1Min, uint256 amount2Min,address to)
    public
    returns (uint256 amountA,uint256 amountB,uint256 liquidity){
        // 
        require(amount1 > 0 && amount2 > 0);
        if (pair.getTokenA() == address(0) && Pair.getTokenB() == address(0))
        {
            Pair.init(token1, token2);
        }else
        //增加流动性
        (amountA, amountB) = _addLiq(amount1,amount2,amount1Min,amount2Min);
        //转账
        _safeTransferFrom(token1, msg.sender, address(Pair), amountA);
        _safeTransferFrom(token2, msg.sender, address(Pair), amountB);
        liquidity = V2Pair(Pair).mint(to);
    }

    //移除流动性
    function removeLiq(uint256 liquidity,uint256 amountAMin,uint256 amountBMin,address addressTo) public returns (uint256 tokenNumA, uint256 tokenNumB) {
        require(amountA >= amountAMin && amountA >= amountBMin);
        // 从池子转出代币
        V2Pair(Fpair).transferFrom(msg.sender, address(Fpair), liquidity);
        // 销毁池子种对应数额的代币
        (tokenNumA, tokenNumB) = V2Pair(Fpair).burn(addressTo);
    
  
    }

  

    //transfer
    function _safeTransferFrom(address token,address from,address to,uint256 value) public {
        FT(token).transferFrom(from, to, value);
    }
    //增加流动性
    function _addLiq(uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin) 
             internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, ) = Pair.getReserve();

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA,reserveB);

        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal > amountBMin);
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint256 amountAOptimal = quote(amountBDesired,reserveB,reserveA);
            assert(amountAOptimal <= amountADesired);
            require(amountAOptimal > amountAMin);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    // 初始化
     function quote( uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn != 0, "Amount is exhausted");
        require(reserveIn != 0 && reserveOut != 0, "Liquidity is exhausted");
        amountOut = (amountIn * reserveOut) / reserveIn;
    }


    function countAmountOut(uint256 amountIn,uint256 reserveIn,uint256 reserveOut) public pure returns (uint256 amount) {
      
        require(reserveIn != 0 && reserveOut != 0, "Liquidity is exhausted");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amount = numerator / denominator;
    }
     function getAmountIn(uint256 amountOut,uint256 reserveIn,uint256 reserveOut) public pure returns (uint256 amountIn) {
        require(amountOut != 0, "Amount is exhausted");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }
   
}
