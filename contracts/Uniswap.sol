// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
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
    // tokens
    address public token0;
    address public token1;

    // reserves
    uint256 private reserve0;
    uint256 private reserve1;

    // liquidity
    uint256 constant MIN_LIQUIDITY = 1000;

    error TransferFailed();
    error Invalid();
    error TokensNotEnough();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();

    constructor(address _token0, address _token1) FT("Swap", "S") {
        token0 = _token0;
        token1 = _token1;
    }

    // addLiquidity
    function addLiquidity() public {
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

        _update(balance0, balance1);
    }

    // removeLiquidity
    function removeLiquidity(address _to) public returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 liquidity = balanceOf(address(this));
        amount0 = (reserve0 * balance0) / totalSupply();
        amount1 = (reserve1 * balance1) / totalSupply();
        _burn(address(this), liquidity);
        _safeTransfer(token0, _to, amount0);
        _safeTransfer(token1, _to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);
    }

    // slip point
    function SlipLimited(uint256 _Amount0out, uint256 _Amount1out, address to) public {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();

        uint256 slippoint = 1;
        uint256 desire;
        uint256 actual;
        if (_Amount0out == 0) {
            desire = (_reserve1 * _Amount1out) / _reserve0;
            actual = swap(_Amount0out, _Amount0out, to);
        } else if (_Amount1out == 0) {
            desire = (_reserve0 * _Amount0out) / _reserve1;
            actual = swap(_Amount1out, _Amount1out, to);
        }
        uint256 slippage = ((desire - actual) * 1000) / desire;
        if (slippage > slippoint) {
            revert TokensNotEnough();
        }
    }

    // swap
    function swap(uint256 _Amount0out, uint256 _Amount1out, address to) public returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        if (_Amount0out == 0 && _Amount1out == 0) {
            revert InsufficientOutputAmount();
        }

        if (_Amount0out > _reserve0 || _Amount1out > _reserve1) {
            revert InsufficientLiquidity();
        }

        if (_Amount0out == 0) {
            FT(token0).transferFrom(
                msg.sender,
                address(this),
                Charge(_Amount1out)
            );
            balance0 -= Charge(_Amount1out);
            balance0 += _Amount1out;
            return _Amount1out;
        } else if (_Amount1out == 0) {
            FT(token1).transferFrom(
                msg.sender,
                address(this),
                Charge(_Amount0out)
            );
            balance1 -= Charge(_Amount0out);
            balance1 += _Amount0out;
            return _Amount0out;
        }

        if (balance0 * balance1 < _reserve0 * _reserve1) {
            revert Invalid();
        }

        _update(balance0, balance1);

        if (_Amount0out > 0) {
            _safeTransfer(token0, to, _Amount0out);
        }
        if (_Amount1out > 0) {
            _safeTransfer(token1, to, _Amount1out);
        }
    }

    // fee charge
    function Charge(uint256 _total) internal pure returns (uint256) {
        uint256 fee = (_total * 997) / 1000;
        return fee;
    }

    // safeTransform
    function _safeTransfer(address _token0, address _to, uint256 _value) private {
        (bool success, bytes memory data) = _token0.call(
            abi.encodeWithSignature("transfer(addtess,uint256)", _to, _value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }

    //getReserve
    function getReserves() public view returns (uint256, uint256, uint32) {
        return (reserve0, reserve1, 0);
    }

    // update
    function _update(uint256 _balance0, uint256 _balance1) private {
        reserve0 = _balance0;
        reserve1 = _balance1;
    }
}