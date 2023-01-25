// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./FT.sol";
import "./Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract UniswapV2 is FT {
    
    address public token0;//token0的定义
    address public token1;//token1的定义

    
    uint256 private reserve0;
    uint256 private reserve1;

    
    uint256 constant MIN_LIQUIDITY = 1000;//对交易池定义

    error TransferFailed();
    error Invalid();
    error TokensNotEnough();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();

    constructor(address _token0, address _token1) FT("LHY", "lhy") {
        token0 = _token0;
        token1 = _token1;
    }

    //增加流动性
    function addLiquidity() public {
        (uint256 _reserve0, uint256 _reserve1, ) = Reserves();

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

    // 移除流动性
    function removeLiquidity(address to) public
        returns (uint256 amount0, uint256 amount1)
    {
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

        _update(balance0, balance1);
    }

    //进行交易
    function swap(uint256 amount0out,uint256 amount1out,address to) public returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1, ) = Reserves();

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
                Charge(amount1out)
            );
            balance0 -= Charge(amount1out);
            balance0 += amount1out;
            return amount1out;
        } else if (amount1out == 0) {
            FT(token1).transferFrom(
                msg.sender,
                address(this),
                Charge(amount0out)
            );
            balance1 -= Charge(amount0out);
            balance1 += amount0out;
            return amount0out;
        }

        if (balance0 * balance1 < _reserve0 * _reserve1) {
            revert Invalid();
        }

        _update(balance0, balance1);

        if (amount0out > 0) {
            _safeTransfer(token0, to, amount0out);
        }
        if (amount1out > 0) {
            _safeTransfer(token1, to, amount1out);
        }
    }

    // 千分之三的手续费用
    function Chargefee(uint256 total) internal pure returns (uint256) {
        uint256 fee = (total * 997) / 1000;
        return fee;
    }

     //滑点功能
    function SlipLimited(
        uint256 amount0out,
        uint256 amount1out,
        address to
    ) public {
        (uint256 _reserve0, uint256 _reserve1, ) = Reserves();

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


    function _safeTransfer(
        address token0,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token0.call(
            abi.encodeWithSignature("transfer(addtess,uint256)", to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }

    function Reserves()
        public
        view
        returns (
            uint256,
            uint256,
            uint32
        )
    {
        return (reserve0, reserve1, 0);
    }

    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
    }
}
