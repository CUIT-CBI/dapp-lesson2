// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FT.sol";
import "./myERC20.sol";

/*
    实验内容
    1. 增加/移出流动性（完成）
    2. 交易功能（完成）
    3. 实现手续费功能，千分之三手续费（完成）
    4. 实现滑点功能（完成）
    5. 实现部署脚本（完成）

    参考文案：
    1. uniswap白皮书(中文版)  https://hearrain.com/uniswap-bai-pi-shu-zhong-wen-ban
    2. uniswap V1源码  https://github.com/Uniswap/v1-contracts/tree/master/contracts
    3. uniswap V2源码  https://github.com/Uniswap/v2-core
*/
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
}

contract Swap is myERC20{
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    address public factory;
    address public TokenA;
    address public TokenB;
    mapping(address => uint256) balances;
    uint256 public totalsupply;
    uint256 reserveA;
    uint256 reserveB;

    constructor(address _token0, address _token1) {
        TokenA = _token0;
        TokenB = _token1;
    }

    function updateRserve() internal returns(uint256, uint256) {
        reserveA = ERC20(TokenA).balanceOf(address(this));
        reserveB = ERC20(TokenB).balanceOf(address(this));
        return (reserveA, reserveB);
    }

    // **** ADD LIQUIDITY ****
    function addLiquidity(uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to) public {
        updateRserve();
        if (reserveA == 0 && reserveB == 0) {
            ERC20(TokenA).transferFrom(msg.sender, address(this), amountADesired);
            ERC20(TokenB).transferFrom(msg.sender, address(this), amountBDesired);
            mint(address(this));
        } else {
            uint amountBOptimal = amountADesired * reserveB / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
                ERC20(TokenA).transferFrom(msg.sender, address(this), amountADesired);
                ERC20(TokenB).transferFrom(msg.sender, address(this), amountBOptimal);
                mint(address(this));
            } else {
                uint amountAOptimal = amountBDesired * reserveA / reserveB;
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                ERC20(TokenA).transferFrom(msg.sender, address(this), amountAOptimal);
                ERC20(TokenB).transferFrom(msg.sender, address(this), amountBDesired);
                mint(address(this));
            }
        }
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(uint liquidity, uint amountAMin, uint amountBMin, address to) public returns (uint amountA, uint amountB) {
        updateRserve();
        transferFrom(msg.sender, address(this), liquidity);
        (uint amount0, uint amount1) = burn(to);
        (address token0,) = TokenA > TokenB ? (TokenB, TokenA) : (TokenA, TokenB);
        (amountA, amountB) = TokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");
    }

    // 交易+滑点
    // 用户有amountInput数量的token，换取另一种token，通过amountOutMin设置用户期待最低的值
    function swapTokenOutput(address _token, uint256 amountInput, uint256 amountOutMin) public {
        if(_token == TokenA) {
            uint amountBOutput = getAmountOut(amountInput, reserveA, reserveB);
            require(amountBOutput >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
            ERC20(TokenA).transferFrom(msg.sender, address(this), amountInput);
            ERC20(TokenB).transfer(msg.sender, amountBOutput);
        } else {
            uint amountAOutput = getAmountOut(amountInput, reserveB, reserveA);
            require(amountAOutput >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
            ERC20(TokenB).transferFrom(msg.sender, address(this), amountInput);
            ERC20(TokenA).transfer(msg.sender, amountAOutput);

            
        }
    }

    // 用户想要交换出amountOutput数量的token，需要另一种token的数量，通过amountInMax设置用户付出最高的值
    function swapTokenInput(address _token, uint256 amountOutput, uint256 amountInMax) public {
        if(_token == TokenA) {
            uint amountBInput = getAmountIn(amountOutput, reserveB, reserveA);
            require(amountBInput <= amountInMax, "INSUFFICIENT_INPUT_AMOUNT");
            ERC20(TokenA).transfer(msg.sender, amountOutput);
            ERC20(TokenB).transferFrom(msg.sender, address(this), amountBInput);
        } else {
            uint amountAInput = getAmountIn(amountOutput, reserveA, reserveB);
            require(amountAInput <= amountInMax, "INSUFFICIENT_INPUT_AMOUNT");
            ERC20(TokenA).transferFrom(msg.sender, address(this), amountAInput);
            ERC20(TokenB).transfer(msg.sender, amountOutput);
        }
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns(uint amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn *1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns(uint amountIn) {
        require(amountOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function mint(address to) internal returns(uint liquidity){
        uint256 balanceA = ERC20(TokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(TokenB).balanceOf(address(this));
        uint256 amountA = balanceA - reserveA;
        uint256 amountB = balanceB - reserveB;
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt((amountA * amountB) - MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
        }
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);
    }

    function burn(address to) internal returns (uint amountA, uint amountB) {
        uint256 balanceA = ERC20(TokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(TokenB).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; 
        amountA = liquidity * balanceA / _totalSupply; 
        amountB = liquidity * balanceB / _totalSupply; 
        require(amountA > 0 && amountB > 0, "INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        ERC20(TokenA).transfer(TokenA, amountA);
        ERC20(TokenB).transfer(TokenB, amountB);
    }
}