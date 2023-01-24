// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FT.sol";

// a library for performing various math operations
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a < b ? a : b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

contract Pair is FT{

    uint public MINIMUM_LP = 10**3;

    address public token0;
    address public token1;

    uint256 public reserve0;
    uint256 public reserve1;

  //创建资金池
    constructor(address _token0, address _token1) FT("LPtoken","LP") {
        token0 = _token0;
        token1 = _token1;
    }

  //获取资金储备数 更新
    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

  //获取资金数
    function getAmount(uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut) private pure returns (uint256 amountOut) {
        amountOut = (reserveIn * reserveOut) / (reserveIn + amountIn);
        return amountOut;
    }


    //增加流动性
    function addLP(uint amount0, uint amount1, address to) external returns(uint LP) {
       require(to != token0 && to != token1, 'to is wrong');
       (uint256 _reserve0, uint256 _reserve1) = getReserves();
       //将token转入交易池储存
       ERC20(token0).transferFrom(msg.sender,address(this),amount0);
       ERC20(token1).transferFrom(msg.sender,address(this),amount1);

       uint256 currentSupply = super.totalSupply();
       uint256 reserveAfter0 = _reserve0 + amount0;
       uint256 reserveAfter1 = _reserve1 + amount1;

       if(currentSupply == 0 ){
           LP = Math.sqrt(amount0 * amount1) - MINIMUM_LP;
           _mint(msg.sender,LP);
       }else{
           uint lp0 = reserveAfter0 * currentSupply / _reserve0;
           uint lp1 = reserveAfter1 * currentSupply / _reserve1;
           LP = Math.min(lp0,lp1);
        }
        super._mint(to,LP);
        //更新交易池里代币的储备数量
        reserve0 = reserveAfter0;
        reserve1 = reserveAfter1;

    }

    //移除流动性
    function removeLP(uint LP) public returns(uint256 amount0, uint256 amount1) {
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        uint256 balance0 = ERC20(token0).balanceOf(address(this));//将代表流动性质的ft代币收回
        uint256 balance1 = ERC20(token1).balanceOf(address(this));
        transfer(address(this),LP);
        uint256 currentTotalLP = super.totalSupply();
        amount0 = LP * _reserve0 / currentTotalLP;  //这部分ft代币在交易池中代表的token0、token1加上手续费的数量
        amount1 = LP * _reserve1 / currentTotalLP;
        
        super._burn(msg.sender,LP);
        ERC20(token0).transfer(msg.sender,amount0);
        ERC20(token1).transfer(msg.sender,amount1);
        balance0 = ERC20(token0).balanceOf(address(this));
        balance1 = ERC20(token1).balanceOf(address(this));
        //还原交易池里面原本代币储备数量
        reserve0 = balance0;
        reserve1 = balance1;
    }

  

    //交易时手续费和滑点实现
    function swap(
        uint256 amountMin,
        uint256 amount0In, 
        uint256 amount1In, 
        address from, 
        address to, 
        address toToken) external{
            require(toToken != from && toToken != to, 'Ft: INVALID_TO');
            (uint256 _reserve0, uint256 _reserve1) = getReserves();
            if(amount0In > 0) ERC20(from).transferFrom(msg.sender, address(this), amount0In);
            if(amount1In > 0) ERC20(from).transferFrom(msg.sender, address(this), amount1In);
            uint256 balance0 = ERC20(token0).balanceOf(address(this));//当前交易池里还剩下token  
            uint256 balance1 = ERC20(token1).balanceOf(address(this));//当前交易池里还剩下token  
            //扣除手续费
            uint256 amount0Out = getAmount(amount0In,_reserve0,_reserve1) * 997 /1000;//以取出减少百分之三实现
            uint256 amount1Out = getAmount(amount1In,_reserve1,_reserve0) * 997 /1000;//以取出减少百分之三实现
            //设置滑点
            if(amount0Out > 0) {
                require(amount0Out >= amountMin,'no more than amountIn');
                ERC20(to).transferFrom(msg.sender,toToken,amount0Out);
            }
            if(amount1Out > 0) {
                require(amount1Out >= amountMin,'no more than amountMin');
                ERC20(to).transferFrom(msg.sender,toToken,amount1Out);
            }
            reserve0 = balance0;
            reserve1 = balance1;
        }

}
