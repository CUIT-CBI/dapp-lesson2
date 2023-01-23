// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FT.sol";
// 实验内容
// 1. 增加/移出流动性                      30分
// 2. 交易功能                            30分
// 3. 实现手续费功能，千分之三手续费          10分
// 4. 实现滑点功能                         15分
// 5. 实现部署脚本                         15分
contract Exchange is FT{

    IERC20 public token1;
    IERC20 public token2;
    uint public reserve1;
    uint public reserve2;
    uint256 liquidity;

    constructor(address _token1,address _token2) FT("Jiangpu","JUMP"){
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }  
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    //初始化流动池
    function initialize(uint256 _amount0, uint256 _amount1) external payable {
        IERC20(token1).transferFrom(msg.sender, address(this), _amount0);
        IERC20(token2).transferFrom(msg.sender, address(this), _amount1);
        //初始化代币余额
        reserve1 = IERC20(token1).balanceOf(address(this));
        reserve2 = IERC20(token2).balanceOf(address(this));

        liquidity = sqrt(_amount0 * _amount1);

        _mint(msg.sender, liquidity);
    }

    //增加流动性
    function addLiquidity(uint _Amount1, uint _Amount2) external{
        
        require (_Amount1 != 0 && _Amount2 != 0);

        if(reserve1 == 0) {
            token1.transferFrom(msg.sender, address(this), _Amount1);
            token2.transferFrom(msg.sender, address(this), _Amount2);
            liquidity = _Amount1;
            reserve1 += _Amount1;
            reserve2 += _Amount2;
            _mint(msg.sender, liquidity);
        } else {

            uint256 _amount1 = (_Amount2 * reserve1) / reserve2;
            require (_Amount1 >= _amount1);
            token1.transferFrom(msg.sender, address(this), _amount1);
            token2.transferFrom(msg.sender, address(this), _Amount2);
            liquidity = (totalSupply() * _amount1) / reserve1;
            reserve1 += _amount1;
            reserve2 += _Amount2;
            _mint(msg.sender, liquidity);
        }
    }
    //移除流动性
    function removeLiquidity(uint256 _Amount1) public {
        require(_Amount1 > 0 && _Amount1 <= (balanceOf(msg.sender) * reserve1) / totalSupply());

        uint256 _amount2 = (_Amount1 * reserve2) / reserve1;

        _burn(msg.sender, _Amount1);

        token1.transfer(msg.sender, _Amount1);
        token2.transfer(msg.sender, _amount2);

        reserve1 -= _Amount1;
        reserve2 -= _amount2;

    }

    //手续费
    function getAmount(uint256 _inputAmount, uint256 _inputReserve, uint256 _outputReserve) internal pure returns (uint256) {
        require( _inputReserve > 0&&_outputReserve > 0,"invalid reserves");
        //手续费千分之五
        uint256  fee = (_inputAmount*5) / 1000;
        uint256  finalAmount = _inputAmount - fee;
        uint256  rate0 = finalAmount*_outputReserve;
        uint256  rate1 = finalAmount + _inputReserve;
        return  rate0/rate1;
    }

    // 交易&滑点
    function token1ToToken2(uint256 slippage, uint256 _amount) public {
        uint256 getAmount = getAmount(_amount, reserve1, reserve2);
        //滑点
        require(getAmount >= slippage , "Bad Deal!");
        IERC20(token1).transferFrom(msg.sender, address(this), _amount);
        IERC20(token2).transferFrom(msg.sender, address(this), getAmount);  
        reserve1 += _amount;
        reserve2 -= getAmount;
        
    }

    function token2toToken1(uint256 slippage, uint256 _amount) public {
        uint256 getAmount = getAmount(_amount, reserve2, reserve1);
        //滑点
        require(getAmount >= slippage , "Bad Deal!");
        IERC20(token1).transferFrom(msg.sender, address(this), _amount);
        IERC20(token2).transferFrom(msg.sender, address(this), getAmount); 
        reserve1 -= getAmount;
        reserve2 += _amount;
    }    
}