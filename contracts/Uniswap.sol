// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract Uniswap is FT {
    address public token0;
    address public token1;
    uint256 private reserve0;
    uint256 private reserve1;
    uint256 constant MIN_LIQUIDITY = 1000;

    error TransferFailed();
    error Invalid();
    error TokensNotEnough();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();

    constructor(address _token0, address _token1) FT("tang", "t") {
        token0 = _token0;
        token1 = _token1;
    }

    
    function add() public {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        uint256 liquidity;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MIN_LIQUIDITY;
            _mint(address(0), MIN_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (totalSupply() * amount0) / _reserve0,
                (totalSupply() * amount1) / _reserve1
            );
        }
        if (liquidity <= 0) {
            revert InsufficientLiquidityMinted();
        }
        _mint(msg.sender, liquidity);

        update(balance0, balance1);
    }

    
    function remove(address to)public returns (uint256 amount0, uint256 amount1){
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 liquidity = balanceOf(address(this));
        amount0 = (reserve0 * balance0) / totalSupply();
        amount1 = (reserve1 * balance1) / totalSupply();
        _burn(address(this), liquidity);
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        update(balance0, balance1);
    }

    function Slip( uint256 amount0out, uint256 amount1out, address to) public {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();

        uint256 slippoint = 1;
        uint256 desire;
        uint256 actual;
        if (amount0out == 0) {
            desire = (_reserve1 * amount1out) / _reserve0;
            actual = swap(amount0out, amount0out, to);
        } else if (amount1out == 0) {
            desire = (_reserve0 * amount0out) / _reserve1;
            actual = swap(amount1out, amount1out, to);
        }
        uint256 slippage = ((desire - actual) * 1000) / desire;
        if (slippage > slippoint) {
            revert TokensNotEnough();
        }
    }

    function swap(uint256 amount0out,uint256 amount1out,address to) public  returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        if (amount0out == 0 && amount1out == 0) {
            revert InsufficientOutputAmount();
        }

        if (amount0out > _reserve0 || amount1out > _reserve1) {
            revert InsufficientLiquidity();
        }

        if (amount0out == 0) {
            FT(token0).transferFrom(
                msg.sender,
                address(this),
                freeCharge(amount1out)
            );
            balance0 -= freeCharge(amount1out);
            balance0 += amount1out;
            return amount1out;
        } else if (amount1out == 0) {
            FT(token1).transferFrom(
                msg.sender,
                address(this),
                freeCharge(amount0out)
            );
            balance1 -= freeCharge(amount0out);
            balance1 += amount0out;
            return amount0out;
        }

        if (balance0 * balance1 < _reserve0 * _reserve1) {
            revert Invalid();
        }

        update(balance0, balance1);

        if (amount0out > 0) {
            _safeTransfer(token0, to, amount0out);
        }
        if (amount1out > 0) {
            _safeTransfer(token1, to, amount1out);
        }
    }

    // fee charge
    function freeCharge(uint256 total) internal pure returns (uint256) {
        uint256 fee = (total * 997) / 1000;
        return fee;
    }

    function _safeTransfer(address token0,address to,uint256 value) private {
        (bool success, bytes memory data) = token0.call(
            abi.encodeWithSignature("transfer(addtess,uint256)", to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }

    function getReserves() public view returns (uint256,uint256,uint32){
        return (reserve0, reserve1, 0);
    }

    
    function update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
    }
}
