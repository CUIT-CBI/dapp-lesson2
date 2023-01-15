// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./FT.sol";

//实验目的
// 熟练掌握ERC20标准，熟悉基于xy=k的AMM实现原理，
// 能实现增加/移除流动性，实现多个token的swap

// 本实验主要需要理解流动性、滑点、手续费等概念，
// 以及uniswap的原理和相关计算

contract Exchange is FT {
    //新建两种代币token0和token1
    address public token0;
    address public token1;
    //两种代币的余额
    uint256 private reserve0;
    uint256 private reserve1;
    //初始流动性为零
    uint256 liquidity = 0;

    uint256 amount0;
    uint256 amount1;

    constructor(address _token0, address _token1) FT("ZC","ZC"){
        token0 = _token0;
        token1 = _token1;
    }

    //以下两个数学函数是为了方便后面计算
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
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

    //创建流动池
    function createPool(uint256 _amount0, uint256 _amount1) external {
        ERC20(token0).transferFrom(msg.sender, address(this), _amount0);
        ERC20(token1).transferFrom(msg.sender, address(this), _amount1);
        //更新两种代币余额
        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));
        //liquidity = sqrt(amount0 * amount1)
        liquidity = sqrt(_amount0 * _amount1);
        
        _mint(msg.sender, liquidity);
    }

    //增加流动性
    function addLiquidity(address _token, uint256 _amount) external returns (uint256) {
        require(_token == token0 || _token == token1, "Incorrect address");
        ERC20(token0).balanceOf(address(this));
        ERC20(token1).balanceOf(address(this));
        if(_token == token1){
            amount1 = _amount;
            //amount0 / reserver0 = amount1 / reserve1
            amount0 = reserve1 * amount0 / reserve1;            
        } else {
            amount0 = _amount;
            //amount1 / reserve1 = amount0 / reserver0
            amount1 = reserve1 * amount0 / reserve0;
        }

        ERC20(token0).transferFrom(msg.sender, address(this), amount0);
        ERC20(token1).transferFrom(msg.sender, address(this), amount1);
        //liquidity / totalSupply = amount / reserve
        liquidity = min(totalSupply() * amount0 / reserve0, totalSupply() * amount1 / reserve1);
        //铸造代币
        _mint(msg.sender, liquidity);

        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));

        return liquidity;
    }

    //移除流动性
    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "_amount should be greater than zero");
        uint256 balance0 = ERC20(token0).balanceOf(address(this));
        uint256 balance1 = ERC20(token1).balanceOf(address(this));
        //amount0 / balance0 = _amount / tatalSupply
        amount0 = _amount * balance0 / totalSupply();
        //amount1 / balance1 = _amount / tatalSupply
        amount1 = _amount * balance1 / totalSupply();
        //销毁代币
        _burn(msg.sender, _amount);

        ERC20(token0).transferFrom(msg.sender, address(this), amount0);
        ERC20(token1).transferFrom(msg.sender, address(this), amount1);

        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));

        return (amount0, amount1);
    }

    //实现手续费功能，获取返回给用户的代币数量
    //滑点是指预期交易价格和实际成交价格之间的差值
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) internal pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Incorrect reserves");

        //收取千分之三手续费
        //(注意solidity无法保存小数)
        //所以可以inputAmountWithFee = (inputAmount - ((inputAmount)*3/1000)) 
        //即((inputAmount)*997)/1000
        uint256 inputAmountWithFee = inputAmount * 997;

        // xy = k
        // (x + Δx) * (y - Δy) = x * y
        // Δy = (y * Δx) / (x + Δx)
        uint256 a = inputAmountWithFee * outputReserve;
        uint256 b = (inputReserve * 1000) + inputAmountWithFee;

        return a / b;
    }

    //token0交易为token1
    function token0ToToken1(uint256 _inputAmount, uint256 _minTokens) public {
        uint256 getAmount = getAmountOfTokens(_inputAmount, reserve0, reserve1);
        require(getAmount >= _minTokens, "Incorrect output amount");

        reserve0 += _inputAmount;
        reserve1 -= getAmount;

        ERC20(token0).transferFrom(msg.sender, address(this), _inputAmount);
        ERC20(token1).transferFrom(msg.sender, address(this), getAmount);  
        //更新余额
        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));   
    }    

    //token1交易为token0
    function token1ToToken0(uint256 _inputAmount, uint256 _minTokens) public {
        //和token0ToToken1大同小异，参数互换即可
        uint256 getAmount = getAmountOfTokens(_inputAmount, reserve1, reserve0);
        require(getAmount >= _minTokens, "Incorrect output amount");

        reserve1 += _inputAmount;
        reserve0 -= getAmount;
        
        ERC20(token1).transferFrom(msg.sender, address(this), _inputAmount);
        ERC20(token0).transferFrom(msg.sender, address(this), getAmount);  
        //更新余额
        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));   
    }

    // //返回持有代币数量
    // function getReserve() internal view returns (uint256 _reserve0, uint256 _reserve1) {
    //     _reserve0 = reserve0;
    //     _reserve1 = reserve1;
    // }
}



