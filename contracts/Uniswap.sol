// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;
import "./FT.sol";
import "./libraries/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
## 实验目的
熟练掌握ERC20标准，熟悉基于xy=k的AMM实现原理，能实现增加/溢出流动性，实现多个token的swap
## 实验内容
### 1. 增加/移出流动性                      30分
### 2. 交易功能                            30分
### 3. 实现手续费功能，千分之三手续费          10分
### 4. 实现滑点功能                         15分
### 5. 实现部署脚本                         15分
## 提交方式
在GitHub仓库的自己的分支下提交Pull Request
 */


contract Uniswap is FT{
    
    //定义输入货币输出货币的地址与货币的存量
    address public token0;
    address public token1;
    //定义池子内货币余额
    uint256 private reserve0;
    uint256 private reserve1;
    //定义最小流动性为1000保证池子有流动性
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error TransferFailed();
    error Invalidk();
    error Notenoughtokens();
    
    event Burn(
        address indexed sender,
        uint256 amount0, 
        uint256 amount1
               );
    event Mint(
        address indexed sender, 
        uint256 amount0, 
        uint256 amount1
               );
    event Sync(
        uint256 reserve0,
        uint256 reserve1
               );
    event Swap(
        address indexed sender,
        uint256 amount0out,
        uint256 amount1out,
        address indexed to
               );
    
    constructor (address _token0,address _token1) FT("UniswapV2","YYL"){
        token0 = _token0;
        token1 = _token1;
    }
     //防止重入攻击
     uint256 private unlocked = 1;
     modifier lock(){
        require(unlocked == 1,'UniswapV2:Locked');
        unlocked = 0;
        _;
        unlocked = 1;
     }
   
     //增加流动性
    function addLiquidity() 
    public {
        (uint256 _reserve0,uint256 _reserve1,) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));    

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        uint256 liquidity;

        if(totalSupply() == 0){
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0),MINIMUM_LIQUIDITY);
        }else{
            liquidity = Math.min(
                (totalSupply() * amount0) / _reserve0,
                (totalSupply() * amount1) / _reserve1
            );
        }
        if(liquidity <= 0){
           revert InsufficientLiquidityMinted();

        } 
        _mint(msg.sender,liquidity);

        _update(balance0,balance1);

        emit Mint(msg.sender,amount0,amount1);
    }
    //移除流动性
    function removeLiquidity(address to) 
    public 
    returns (uint256 amount0,
             uint256 amount1){
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));   

        uint256 liquidity = balanceOf(address(this));
        amount0 = reserve0 * balance0 / totalSupply();
        amount1 = reserve1 * balance1 / totalSupply();
        _burn(address(this),liquidity);
        _safeTransfer(token0,to,amount0);
        _safeTransfer(token1,to,amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0,balance1);

        emit Burn(msg.sender,amount0,amount1);
    }
    //核心交易
    function swap(
        uint256 amount0out,
        uint256 amount1out,
        address to
    ) public lock returns(uint256){
        (uint256 _reserve0,uint256 _reserve1,) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));    

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        uint256 L = amount0 * amount1;
        if(amount0out == 0 && amount1out ==0){
            revert InsufficientOutputAmount();
        }

        if(amount0out > _reserve0 || amount1out > _reserve1){
            revert InsufficientLiquidity();
        }

        if(amount0out == 0){
            FT(token0).transferFrom(msg.sender, address(this),Charge(amount1out));
            balance0 -= Charge(amount1out);
            balance0 += amount1out; 
            return amount1out;
        }else 
        if(amount1out == 0){
            FT(token1).transferFrom(msg.sender, address(this),Charge(amount0out));
            balance1 -= Charge(amount0out);
            balance1 += amount0out; 
            return amount0out;
        }

         if(balance0 * balance1 < _reserve0 * _reserve1){
            revert Invalidk();
        }

        _update(balance0,balance1);

        if(amount0out > 0){
            _safeTransfer(token0,to,amount0out);
        }
        if(amount1out > 0){
            _safeTransfer(token1,to,amount1out);
        }
        

        emit Swap(msg.sender,amount0out,amount1out,to);
        
    }
    //获取千分之三小费
    function Charge(uint256 total) 
    public 
    pure
    returns(uint256){
        uint256 charge = total * 997 / 1000;
        return charge;
    }
    //添加滑点功能
    function SlipPageLimited(
        uint256 amount0out,
        uint256 amount1out,
        address to
        )
    public
    
    returns(bool){
        (uint256 _reserve0,uint256 _reserve1,) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));    

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint256 slippoint = 1;
        uint256 desire;
        uint256 actual;
        if(amount0out == 0){
            desire = _reserve1 * amount1out / _reserve0;
            actual = swap(amount0out,amount0out,to);
        }else 
        if(amount1out == 0){
            desire = _reserve0 * amount0out / _reserve1;
            actual = swap(amount1out,amount1out,to);
        }
        uint256 slippage = (desire - actual) * 1000 / desire;
        if(slippage > slippoint){
            revert Notenoughtokens();
        }
        
    }

    //getReserve工具函数
    function getReserves()
    public 
    view 
    returns(
        uint256,
        uint256,
        uint32){
            return(reserve0,reserve1,0);
    }
    //_update工具函数
    function _update(
        uint256 balance0,
        uint256 balance1
    )private{
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(balance0,balance1);
    }
    //safeTransform工具函数
    function _safeTransfer(
        address token0,
        address to,
        uint256 value) 
        private {
            (bool success , bytes memory data) = token0.call(
                abi.encodeWithSignature("transfer(addtess,uint256)", to , value)
            );
            if(!success || (data.length != 0 && !abi.decode(data,(bool)))){
                revert TransferFailed();
            }

    }
    
}
