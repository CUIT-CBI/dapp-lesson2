// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./GcyERC20.sol";//tokenA、tokenB
import "./FT.sol";//LPToken

contract GcyPool is FT {
    //本实验不对代币地址进行排序，默认token0=address(tokenA),token1=address(tokenB)
    GcyERC20 public token0;//交易对中两种代币的合约地址
    GcyERC20 public token1;

    uint public reserve0;//两种代币的储备量
    uint public reserve1; 

    event Sync(uint reserve0, uint reserve1);//事件更新两种币的储备量
    event AddLiquidity(address indexed operator, uint liquidity);//事件增加流动性
    event RemoveLiquidity(address indexed operator, uint liquidity);//事件移除流动性
    event SwapExactToken(address indexed operator, uint amountOut, uint slipPrice);//事件确定输入的交易
    event SwapForExactToken(address indexed operator, uint amountOut, uint slipPrice);//事件确定输出的交易

    constructor(GcyERC20 _token0, GcyERC20 _token1) FT('LPToken', 'LP') {
        require(address(_token0) != address(0),'zero address');
        require(address(_token1) != address(0),'zero address');
        token0 = _token0;
        token1 = _token1;
    }
    
    //同步实时代币余额到储备量
    function _SyncReserves() private {
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
        emit Sync(reserve0, reserve1);
    }

    //获得两种代币的储备量
    function getReserves() external view returns (uint _reserve0, uint _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    //增加流动性
    function addLiquidity(uint amountA, uint amountB) external returns (uint amountAFinal, uint amountBFinal, uint liquidity) {
        uint _totalSupply = totalSupply();
        require(amountA>0 && amountB>0, 'invalid amount');
        //首次铸币时按任意比例投，本实验自定义设置了初始流动性
        if (_totalSupply == 0) {
            //起初我想设置为(amountA*amountB)/2，后考虑到因精度影响初始流动性太大故改为+
            //即 使得初始流动性不小于A、B总和的一半
            liquidity = (amountA+amountB) / 2;
        }else{
            //没有按比例投入就按比例重新分配
            if (amountA/reserve0 != amountB/reserve1) {
                amountB = (amountA*reserve1) / reserve0;
            }
            liquidity = (amountA*_totalSupply) / reserve0;//根据Δlp = Δx/x*lp计算
        }
        //这样写无法实现授权，故本实验采用手动授权
        //token0.approve(address(this), amountA);//需要授权才能转账投入币
        //token1.approve(address(this), amountB);
        token0.transferFrom(msg.sender, address(this), amountA);
        token1.transferFrom(msg.sender, address(this), amountB);
        super._mint(msg.sender, liquidity);
        amountAFinal = amountA;
        amountBFinal = amountB;
        _SyncReserves();
        emit AddLiquidity(msg.sender, liquidity);
    }

    //移除流动性
    function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
        uint _totalSupply = totalSupply();
        require(liquidity>0 && liquidity<=_totalSupply, 'invalid liquidity');
        amount0 = (liquidity * reserve0) / _totalSupply;//根据Δlp = (Δx/x) * lp计算。防止精度丢失过多，先*后/
        amount1 = (liquidity * reserve1) / _totalSupply;
        super._burn(msg.sender, liquidity);
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        _SyncReserves(); 
        emit RemoveLiquidity(msg.sender, liquidity);
    }

    //交易功能、手续费功能、滑点功能
    //swap在一对token之间
    //收取千分之三的交易手续费
    //本实验忽略开发手续费，即不从流动性供给者中分走1/6手续费给开发者
    //考虑到交易手续费因投入单一币不同较复杂无法统一累计后在移除流动性时提取，故暂且留在交易池中

    //swap:以一种确定数目的token换取另一种token
    function swapExactTokenForToken(uint amountAIn, uint amountBIn) external  returns (uint amountOut, uint slipPrice) {
        require(amountAIn>=0 && amountBIn>=0, 'invalid amountIn');
        //判断以A换取B还是以B换取A，投入为0代表被换取
        uint amountIn = amountAIn > 0 ? amountAIn : amountBIn;
        (uint reserveIn, uint reserveOut) = amountAIn > 0 ? (reserve0, reserve1) : (reserve1, reserve0);
        //收取千分之三手续费后实际注入的token，不支持浮点数，分子分母同×1000，与Uniswap处理方法相同
        uint amountInAfterFee = amountIn * 997;
        //根据x*y = (x+Δx)*(y-Δy)，Δy=Δx*y/(x+Δx)计算，并算上手续费
        amountOut = (amountInAfterFee*reserveOut) / (reserveIn*1000 + amountInAfterFee);
        //滑点根据Δx/Δy-x/y=Δx/y计算，这里省略推导过程。×1000000000000000000的目的是防止精度丢失
        slipPrice = (amountIn*1000000000000000000) / reserveOut;
        if (amountIn == amountAIn) {
            //同上，手动授权
            token0.transferFrom(msg.sender, address(this), amountIn);
            token1.transfer(msg.sender, amountOut);
        }else{
            token1.transferFrom(msg.sender, address(this), amountIn);
            token0.transfer(msg.sender, amountOut);
        }
        _SyncReserves(); 
        emit SwapExactToken(msg.sender, amountOut, slipPrice);
    }

    //swap:以一种token换取另一种确定数目的token
    function swapTokenForExactToken(uint amountAOut, uint amountBOut) external returns (uint amountIn, uint slipPrice) {
        require(amountAOut>=0 && amountBOut>=0, 'invalid amountOut');
        //判断以A换取B还是以B换取A，换取不为0代表被换取
        uint amountOut = amountAOut > 0 ? amountAOut : amountBOut;
        (uint reserveIn, uint reserveOut) = amountAOut > 0 ? (reserve1, reserve0) : (reserve0, reserve1);
        //根据x*y = (x+Δx)*(y-Δy)，Δx=x*Δy/(y-Δy)计算，并算上手续费
        amountIn = (reserveIn*amountOut*1000) / (997*reserveOut-997*amountOut);
        //滑点根据Δx/Δy-x/y=Δx/y计算，这里省略推导过程。×1000000000000000000的目的是防止精度丢失
        slipPrice = (amountIn*1000000000000000000) / reserveOut;
        if (amountOut == amountAOut) {
            //同上，手动授权
            token1.transferFrom(msg.sender, address(this), amountIn);
            token0.transfer(msg.sender, amountOut);
        }else{
            token0.transferFrom(msg.sender, address(this), amountIn);
            token1.transfer(msg.sender, amountOut);
        }
        _SyncReserves(); 
        emit SwapForExactToken(msg.sender, amountIn, slipPrice);
    }
}


