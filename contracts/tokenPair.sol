// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./Math.sol";
import './FT.sol';
import "hardhat/console.sol";


contract uniswapV2Pair is FT, Math {

    uint256 constant MINIMUM_LIQUIDITY = 10;

    address public token0;
    address public token1;

    uint256 private reserve0;
    uint256 private reserve1;

    constructor(address token0_, address token1_) FT("myPair", "lp") {
        token0 = token0_;
        token1 = token1_;
    }

    // 添加流动性时，铸造LP token
    function mintLP(address to) public returns (uint256 liquidity) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(this), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply()) / reserve0,
                (amount1 * totalSupply()) / reserve1
            );
        }

        require(liquidity > 0, "the liquidity should greater than 0");

        _mint(to, liquidity);
        _update(balance0, balance1);
    }

    // 移除流动性时，销毁LP token
    // 等比例获得收益
    function burnLP(address to) public returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        amount0 = (liquidity * balance0) / totalSupply();
        amount1 = (liquidity * balance1) / totalSupply();

        require(amount0 != 0 && amount1 != 0, "the amount cannot be 0");

        _burn(address(this), liquidity);

        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) public {
        require(amount0Out != 0 || amount1Out != 0, "the amountOut cannot all be 0");

        require(amount0Out <= reserve0 && amount1Out <= reserve1, "the amountOut should all less than or equal reserve");

        // 两种情况
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);
    }

    function getTokenReserve(address token) external view returns (uint256){
        if(token == token0) return reserve0;
        if(token == token1) return reserve1;
        return 0;
    }

    function getToken0() external view returns (address) {
        return token0;
    }

    function getToken1() external view returns (address) {
        return token1;
    }

    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        FT(token).transfer(to, value);
    }
}
