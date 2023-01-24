// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HYXbusiness is ERC20 {
    address public token0;
    address public token1;

    // 账户对应储量
    uint256 public Reserve0;
    uint256 public Reserve1;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    //构造交易池
    constructor(address _token0, address _token1) ERC20("HYX", "HYX1") {
        token0 = _token0;
        token1 = _token1;
    }

    //  添加流动性
    function addliquidity(uint256 _amount0, uint256 _amount1) public {
        require(_amount0 != 0 && _amount1 != 0, "addliquidity fasle");
        uint256 Liquidity;
        if (Reserve0 != 0) {
            uint256 bestReserve = (_amount0 * Reserve0) / Reserve1;
            require(_amount0 > bestReserve, "need more tokenamount");
            assert(
                IERC20(token0).transferFrom(
                    msg.sender,
                    address(this),
                    bestReserve
                )
            );
            assert(
                IERC20(token1).transferFrom(msg.sender, address(this), _amount1)
            );
            uint256 currentSupply = totalSupply();
            uint256 Liquidity0 = (Reserve0 * currentSupply) / Reserve0;
            uint256 Liquidity1 = (Reserve1 * currentSupply) / Reserve1;
            Liquidity = Math.min(Liquidity0, Liquidity1);
            _mint(msg.sender, Liquidity);
            Reserve0 += bestReserve;
            Reserve1 += _amount1;
        } else {
            assert(
                IERC20(token0).transferFrom(msg.sender, address(this), _amount0)
            );
            assert(
                IERC20(token1).transferFrom(msg.sender, address(this), _amount1)
            );
            Liquidity = Math.sqrt(_amount0 * _amount1) + (MINIMUM_LIQUIDITY);
            _mint(msg.sender, Liquidity);
            Reserve0 += _amount0;
            Reserve1 += _amount1;
        }
    }

    //移除流动性
    function removeLiquidity(uint256 liquidity) public {
        //收回代币
        assert(transfer(address(this), liquidity));
        uint256 currentSupply = totalSupply();
        uint256 amount0 = (liquidity * Reserve0) / currentSupply;
        uint256 amount1 = (liquidity * Reserve1) / currentSupply;
        //销毁该用户的代币
        _burn(address(this), liquidity);
        assert(IERC20(token0).transfer(msg.sender, amount0));
        assert(IERC20(token1).transfer(msg.sender, amount1));
        Reserve0 -= amount0;
        Reserve1 -= amount1;
    }

    //获取交易数量
    function getAmount(
        uint256 _amount,
        uint256 _ReserveInput,
        uint256 _ReserveOutput
    ) public pure returns (uint256) {
        //百分之三手续费
        uint256 _swapAmountwithoutfee = ((997 * (_ReserveOutput * _amount)) / 1000) *(_ReserveInput + _amount);
        return _swapAmountwithoutfee;
    }

    //实现交易，滑点
    function swapToken0toToken1(uint256 _minReserve, uint256 _amount) public {
        uint256 amount = getAmount(_amount, Reserve0, Reserve1);
        require(amount >= _minReserve, "no enough");
        assert(IERC20(token0).transferFrom(msg.sender, address(this), _amount));
        assert(IERC20(token1).transfer(msg.sender, amount));
        Reserve0 += _amount;
        Reserve1 -= amount;
    }

    function swapToken1toToken0(uint256 _minReserve, uint256 _amount) public {
        uint256 amount = getAmount(_amount, Reserve1, Reserve0);
        require(amount >= _minReserve, "no enough");
        assert(IERC20(token0).transfer(msg.sender, amount));
        assert(IERC20(token1).transferFrom(msg.sender, address(this), _amount));
        Reserve0 -= amount;
        Reserve1 += _amount;
    }
}
