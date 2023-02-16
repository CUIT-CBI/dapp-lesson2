// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './LPToken.sol';
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract uniswapCore is LPToken {
    using SafeMath  for uint;
    //定义两种代币的地址
    address public token0;
    address public token1; 

    //uint public constant MINIMUM_LIQUIDITY = 10**3;
    
    event Mint(address indexed sender, uint amount0,uint amount1); 
    event Burn(address indexed sender, uint amount0, uint amount1, address to);
    event Swap(address indexed from,address to, uint amountInput, uint amountOutput);
    
    constructor(string memory name, string memory symbol) LPToken(name, symbol) {}
    
    //增加流动性
    function addLiquidity(uint amount0,uint amount1) public returns(uint Liquidity){
        //计算现在池中AB两种代币的数量
        uint _reserve0 = IERC20(token0).balanceOf(address(this));
        uint _reserve1 = IERC20(token1).balanceOf(address(this));
        //用户将代币转移到流动性池中
        assert(IERC20(token0).transferFrom(msg.sender,address(this),amount0));
        assert(IERC20(token1).transferFrom(msg.sender,address(this),amount1));       
        //流动性代币
        uint resLiqu = totalSupply();
        //判断现池中是否有流动性
        if(resLiqu == 0){
            //此时说明是初始添加流动性;
            Liquidity = Math.sqrt(amount0.mul(amount1));
        }else{
            uint newSupplyGivenReserve0 = amount0.mul(resLiqu) / _reserve0;
            uint newSupplyGivenReserve1 = amount1.mul(resLiqu) / _reserve1;
            //取最小值
            Liquidity = Math.min(newSupplyGivenReserve0,newSupplyGivenReserve1);
        }
        require(Liquidity > 0);
        _mint(msg.sender,Liquidity);
        emit Mint(msg.sender,amount0,amount1);
    }

    //移出流动性
    function removeLiquidity(address to) public returns(uint amount0,uint amount1){
        //得到该用户拥有的流动性代币
        uint liquidity = balanceOf(msg.sender); 
        //验证msg.sender是否为流动性提供者
        require(liquidity != 0);
        //得到AB两种现在的数量
        uint _reserve0 = IERC20(token0).balanceOf(address(this));
        uint _reserve1 = IERC20(token1).balanceOf(address(this));
        //得到总的流动性代币数量
        uint resLiqu = totalSupply();
        //计算移除流动性后所返回的AB数量
        amount0 = liquidity.mul(_reserve0) / resLiqu;
        amount1 = liquidity.mul(_reserve1) / resLiqu;
        require(amount0 > 0 && amount1 > 0);
        //销毁流动性代币
        _burn(msg.sender,liquidity);
        //将AB两种代币发送给用户
        IERC20(token0).transfer(to,amount0);
        IERC20(token1).transfer(to,amount1);

        emit Burn(msg.sender,amount0,amount1,to);
    }

    //用一定数量的A代币换取B代币+滑点功能
    function swap1by0(uint amount0,uint minAmount0,address to) public returns(uint amount1){
        require(amount0 > 0 && minAmount0 > 0);
        //得到AB两种代币现在的数量
        uint _reserve0 = IERC20(token0).balanceOf(address(this));
        uint _reserve1 = IERC20(token1).balanceOf(address(this));
        //先将A传入流动性池中
        IERC20(token0).transferFrom(msg.sender,address(this),amount0);
        //计算需要得到多少B代币
        amount1 = inputFee(amount0, _reserve0, _reserve1);
        //判断购买的B代币是否大于用户所期望的最小值
        require(amount1 > minAmount0);
        //将B传给用户
        IERC20(token1).transfer(to, amount1);

        emit Swap(address(this), to, amount0, amount1);
    }

    //用一定数量的B换取A代币+滑点功能
    function swap0by1(uint amount1,uint minAmount1,address to) public returns(uint amount0){
        require(amount1 > 0 && minAmount1 > 0);
        uint _reserve0 = IERC20(token0).balanceOf(address(this));
        uint _reserve1 = IERC20(token1).balanceOf(address(this));
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        amount0 = inputFee(amount1, _reserve1, _reserve0);
        require(amount0 > minAmount1);
        IERC20(token0).transfer(to, amount0);

        emit Swap(address(this), to, amount1, amount0);
    }

    //如果需要一定数量的币则要输入多少数量币

    //要得到一定数量的B要需要多少A代币
    function get1by0(uint outputAmount1,uint maxInput) public returns(uint inputAmount0) {
        require(outputAmount1 > 0 && maxInput > 0);
        //AB两种代币的数量
        uint _reserve0 = IERC20(token0).balanceOf(address(this));
        uint _reserve1 = IERC20(token1).balanceOf(address(this));
        //用户所要花费的A代币的数量
        inputAmount0 = outputFee(outputAmount1, _reserve0, _reserve1);

        require(inputAmount0 <= maxInput);
        //将A代币转移给合约中
        IERC20(token0).transferFrom(msg.sender, address(this), inputAmount0);
        //将B代币转移给用户
        IERC20(token1).transfer(msg.sender, outputAmount1);

        emit Swap(address(this), msg.sender, inputAmount0, outputAmount1);
    }
    //得到一定数量的A需要输入多少的B代币
    function get0by1(uint outputAmount0,uint maxInput) public returns(uint inputAmount1){
        require(outputAmount0 > 0 && maxInput > 0);
        uint _reserve0 = IERC20(token0).balanceOf(address(this));
        uint _reserve1 = IERC20(token1).balanceOf(address(this));
        inputAmount1 = outputFee(outputAmount0, _reserve1, _reserve0);
        require(inputAmount1 <= maxInput);
        IERC20(token1).transferFrom(msg.sender, address(this), inputAmount1);
        IERC20(token0).transfer(msg.sender, outputAmount0);

        emit Swap(address(this), msg.sender, inputAmount1, outputAmount0);
    }

    //实现手续费功能，千分之三手续费-0.3%
    function inputFee(uint amountIn,uint reserve0In,uint reserve1Out) public pure returns(uint amountOut){
        uint feeOn = amountIn.mul(997);
        uint molecule = feeOn.mul(reserve1Out); //分子
        uint denominator = feeOn.add(reserve0In.mul(1000)); //分母
        amountOut = molecule / denominator;
    }

    function outputFee(uint outputAmount,uint inputReserve,uint ouputReserve) public pure returns(uint amount){
        uint molecule = inputReserve.mul(outputAmount).mul(1000);
        uint denominator = (ouputReserve.sub(outputAmount)).mul(997);
        amount = molecule / denominator + 1;
    }
}