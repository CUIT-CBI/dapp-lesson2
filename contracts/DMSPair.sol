// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "../lib/Math.sol";
import './FT.sol';

contract DMSPair is FT, Math {
    uint32 private blockTimes;
    uint256 constant MINIMUM_LIQUIDITY = 8;
    //代币
    address public tokenA;
    address public tokenB;
    //余额
    uint112 private reserveA;
    uint112 private reserveB;




    event Swap(address indexed sender,uint256 amount0Out,uint256 amount1Out,address indexed to);
    event Burn(address indexed sender,uint256 amount0,uint256 amount1, address to);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event SyncReserve(uint256 reserveA, uint256 reserveA);
   

  

    constructor() FT("DMS", "DMStoken") {}

    function init(address token0_, address token1_) public {
        require(token0 == address(0) && token1 == address(0));
        tokenA = token0_;
        tokenB = token1_;
    }

    function mint(address to) public returns (uint256 liquidity) {
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        uint256 balance0 = IERC20(tokenA).balanceOf(address(this));
        uint256 balance1 = IERC20(tokenA).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0_;
        uint256 amount1 = balance1 - reserve1_;
        if (totalSupply() == 0) {
            liquidity = Math.sqr(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(this), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.minVar(
                (amount0 * totalSupply()) / reserve0_,
                (amount1 * totalSupply()) / reserve1_
            );
        }
        require(liquidity > 0);
        _mint(to, liquidity);
        _update(balance0, balance1);
        emit Mint(to, amount0, amount1);
    }

    function burn(address to) public returns (uint256 amount0, uint256 amount1){
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));
        amount0 = (liquidity * balance0) / totalSupply();
        amount1 = (liquidity * balance1) / totalSupply();
        require(amount0 != 0 && amount1 != 0);
        _burn(address(this), liquidity);

        _safeTransfer(tokenA, to, amount0);
        _safeTransfer(tokenB, to, amount1);

        balance0 = IERC20(tokenA).balanceOf(address(this));
        balance1 = IERC20(tokenB).balanceOf(address(this));

        _update(balance0, balance1);

        emit Burn(msg.sender, amount0, amount1, to);
    }
    
    function _safeTransfer(address token,address to,uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        require(success || (data.length == 0 && abi.decode(data, (bool))));
    }

    function swap(uint256 numAOut,uint256 numBOut,address to) public  {
    
        require(numAOut != 0 || numBOut != 0);

        (uint112 reserve0_, uint112 reserve1_, ) = getReserve();

        require(numAOut <= reserve0_ &&numBOut <= reserve1_);

        if (amountAOut > 0) {
            _safeTransfer(tokenA, to, amountAOut);
        }
        if (amountBOut > 0) {
            _safeTransfer(token1, to, amountBOut);
        }
        uint256 balance0 = IERC20(tokenA).balanceOf(address(this));
        uint256 balance1 = IERC20(tokenA).balanceOf(address(this));
        uint256 amount0In = balance0 > reserveA - amountAOut
        ? balance0 - (reserveA - amountAOut): 0;
        uint256 amount1In = balance1 > reserveB - amountBOut
        ? balance1 - (reserveA - amountBOut): 0;

        require(amount0In != 0 || amount1In != 0, "Amount is exhausted");

      
        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

        require(
            balance0Adjusted * balance1Adjusted >=
            uint256(reserve0_) * uint256(reserve1_) * (1000**2), "ivalidError");

        _update(balance0, balance1);
        emit Swap(msg.sender, amountAOut, amountBOut, to);
    }

    function getToken0() external view returns (address) {
        return token0;
    }

    function getToken1() external view returns (address) {
        return token1;
    }

    function getReserve() public view returns (uint112,uint112,uint32){
        return (reserveA, reserveB,blockTimes);
    }

    function getTokenReserve(address token) external view returns (uint112){
        if(token == token0) return reserveA;
        if(token == token1) return reserveB;
        return 0;
    }
    //准备金与余额匹配，按照余额匹配储备量进行更新
    function _update(uint256 balance0,uint256 balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max);
        reserveA = uint112(balance0);
        reserveB = uint112(balance1);
        emit SyncReserve(reserveA, reserveB);
    }

}
