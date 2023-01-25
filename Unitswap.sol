// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./FT.sol";
import "./Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Uniswap is FT {
    address public tokenA;
    address public tokenB;
    uint256 private reserveA;
    uint256 private reserveB;
    uint256 constant LIT_LIQUIDITY = 1000;

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

    // 增加流动性
    function addLiquidity() public {
        (uint256 _reserveA, uint256 _reserveB, ) = getReserves();

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        uint256 amountA = balanceA - _reserveA;
        uint256 amountB = balanceB - _reserveB;
        uint256 liquidity;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amountA * amountB) - LIT_LIQUIDITY;
            _mint(address(0), LIT_LIQUIDITY);
        } else {
            liquidity = Math.lit(
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

    // 去除流动性
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

    //滑点
    function SlipLimited(
        uint256 Aout,
        uint256 Bout,
        address to
    ) public {
        (uint256 _reserveA, uint256 _reserveB, ) = getReserves();

        uint256 slippoint = 1;
        uint256 desire;
        uint256 actual;
        if (Aout == 0) {
            desire = (_reserveB * Bout) / _reserveA;
            actual = swap(Aout, Aout, to);
        } else if (Bout == 0) {
            desire = (_reserveA * Aout) / _reserveB;
            actual = swap(Bout, Bout, to);
        }
        uint256 slippage = ((desire - actual) * 1000) / desire;
        if (slippage > slippoint) {
            revert TokensNotEnough();
        }
    }


    function swap(
        uint256 Aout,
        uint256 Bout,
        address to
    ) public returns (uint256) {
        (uint256 _reserveA, uint256 _reserveB, ) = getReserves();

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        if (Aout == 0 && Bout == 0) {
            revert InsufficientOutputAmount();
        }

        if (Aout > _reserveA || Bout > _reserveB) {
            revert InsufficientLiquidity();
        }

        if (Aout == 0) {
            FT(tokenA).transferFrom(
                msg.sender,
                address(this),
                Charge(Bout)
            );
            balanceA -= Charge(Bout);
            balanceA += Bout;
            return Bout;
        } else if (Bout == 0) {
            FT(tokenB).transferFrom(
                msg.sender,
                address(this),
                Charge(Aout)
            );
            balanceB -= Charge(Aout);
            balanceB += Aout;
            return Aout;
        }

        if (balanceA * balanceB < _reserveA * _reserveB) {
            revert Invalid();
        }

        _update(balanceA, balanceB);

        if (Aout > 0) {
            _safeTransfer(tokenA, to, Aout);
        }
        if (Bout > 0) {
            _safeTransfer(tokenB, to, Bout);
        }
    }


    function Charge(uint256 total) internal pure returns (uint256) {
        uint256 fee = (total * 997) / 1000;
        return fee;
    }

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

    function _update(uint256 balanceA, uint256 balanceB) private {
        reserveA = balanceA;
        reserveB = balanceB;
    }
}
