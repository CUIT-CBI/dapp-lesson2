// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
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
    address public tokenA;
    address public tokenB;

    // reserves
    uint256 private reserveA;
    uint256 private reserveB;

    // liquidity
    uint256 constant MIN_LIQUIDITY = 1000;

    error TransferFailed();
    error Invalid();
    error TokensNotEnough();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();

    constructor(address _tokenA, address _tokenB) FT("Uni", "U") {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // addLiquidity
    function addLiquidity() public {
        (uint256 _reserveA, uint256 _reserveB, ) = getReserves();

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        uint256 amountA = balanceA - _reserveA;
        uint256 amountB = balanceB - _reserveB;
        uint256 liquidity;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amountA * amountB) - MIN_LIQUIDITY;
            _mint(address(0), MIN_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (totalSupply() * amountA) / _reserveA,
                (totalSupply() * amountB) / _reserveB
            );
        }
        if (liquidity <= 0) {
            revert InsufficientLiquidityMinted();
        }
        _mint(msg.sender, liquidity);

        _update(balanceA, balanceB);
    }

    // removeLiquidity
    function removeLiquidity(address to)
        public
        returns (uint256 amountA, uint256 amountB)
    {
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        uint256 liquidity = balanceOf(address(this));
        amountA = (reserveA * balanceA) / totalSupply();
        amountB = (reserveB * balanceB) / totalSupply();
        _burn(address(this), liquidity);
        _safeTransfer(tokenA, to, amountA);
        _safeTransfer(tokenB, to, amountB);

        balanceA = IERC20(tokenA).balanceOf(address(this));
        balanceB = IERC20(tokenB).balanceOf(address(this));

        _update(balanceA, balanceB);
    }

    // slip point
    function SlipLimited(
        uint256 amountAout,
        uint256 amountBout,
        address to
    ) public {
        (uint256 _reserveA, uint256 _reserveB, ) = getReserves();

        uint256 slippoint = 1;
        uint256 desire;
        uint256 actual;
        if (amountAout == 0) {
            desire = (_reserveB * amountBout) / _reserveA;
            actual = swap(amountAout, amountAout, to);
        } else if (amountBout == 0) {
            desire = (_reserveA * amountAout) / _reserveB;
            actual = swap(amountBout, amountBout, to);
        }
        uint256 slippage = ((desire - actual) * 1000) / desire;
        if (slippage > slippoint) {
            revert TokensNotEnough();
        }
    }

    // swap
    function swap(
        uint256 amountAout,
        uint256 amountBout,
        address to
    ) public returns (uint256) {
        (uint256 _reserveA, uint256 _reserveB, ) = getReserves();

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        if (amountAout == 0 && amountBout == 0) {
            revert InsufficientOutputAmount();
        }

        if (amountAout > _reserveA || amountBout > _reserveB) {
            revert InsufficientLiquidity();
        }

        if (amountAout == 0) {
            FT(tokenA).transferFrom(
                msg.sender,
                address(this),
                Charge(amountBout)
            );
            balanceA -= Charge(amountBout);
            balanceA += amountBout;
            return amountBout;
        } else if (amountBout == 0) {
            FT(tokenB).transferFrom(
                msg.sender,
                address(this),
                Charge(amountAout)
            );
            balanceB -= Charge(amountAout);
            balanceB += amountAout;
            return amountAout;
        }

        if (balanceA * balanceB < _reserveA * _reserveB) {
            revert Invalid();
        }

        _update(balanceA, balanceB);

        if (amountAout > 0) {
            _safeTransfer(tokenA, to, amountAout);
        }
        if (amountBout > 0) {
            _safeTransfer(tokenB, to, amountBout);
        }
    }

    // fee charge
    function Charge(uint256 total) internal pure returns (uint256) {
        uint256 fee = (total * 997) / 1000;
        return fee;
    }

    // safeTransform
    function _safeTransfer(
        address tokenA,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = tokenA.call(
            abi.encodeWithSignature("transfer(addtess,uint256)", to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }

    //getReserve
    function getReserves()
        public
        view
        returns (
            uint256,
            uint256,
            uint32
        )
    {
        return (reserveA, reserveB, 0);
    }

    // update
    function _update(uint256 balanceA, uint256 balanceB) private {
        reserveA = balanceA;
        reserveB = balanceB;
    }
}