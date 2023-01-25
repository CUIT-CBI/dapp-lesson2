// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

//  实验内容
// 1. 增加/移出流动性                      
// 2. 交易功能                         
// 3. 实现手续费功能，千分之三手续费        
// 4. 实现滑点功能                         
// 5. 实现部署脚本

import "./ERC20.sol";
import "./FT.sol";

contract SwapPool is FT {
    //两种代币的合约地址
    ERC20 public tokenA;
    ERC20 public tokenB;
    //两种代币的储备量
    uint public reserveA;
    uint public reserveB; 
    
    event Update(uint reserveA, uint reserveB);//更新代币储备量
    event AddLiquidity(address indexed operator, uint liquidity);//增加流动性
    event RemoveLiquidity(address indexed operator, uint liquidity);//移除流动性

    constructor(ERC20 _tokenA, ERC20 _tokenB) FT('LPToken', 'LP') {
        require(address(_tokenA) != address(0),'zero address');
        require(address(_tokenB) != address(0),'zero address');
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function updateReserve() private {
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
        emit Update(reserveA, reserveB);
    }

    //获得代币的储备量
    function getReserves() external view returns (uint _reserveA, uint _reserveB) {
        _reserveA = reserveA;
        _reserveB = reserveB;
    }

    //增加流动性
    function addLiquidity(uint amountA, uint amountB) external returns (uint AFinalAmount, uint BFinalAmount, uint liquidity) {
        uint _totalSupply = totalSupply();
        require(amountA > 0 && amountB > 0, "Error: invalid amount");
        if (_totalSupply == 0) {
            liquidity = (amountA + amountB) / 2;
        }else{
            if (amountA/reserveA != amountB/reserveB) {
                amountB = (amountA*reserveB) / reserveA;
            }
            liquidity = (amountA*_totalSupply) / reserveA;
        }
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        super._mint(msg.sender, liquidity);
        AFinalAmount = amountA;
        BFinalAmount = amountB;
        updateReserve();
        emit AddLiquidity(msg.sender, liquidity);
    }

    //移除流动性
    function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
        uint _totalSupply = totalSupply();
        require(liquidity>0 && liquidity<=_totalSupply, "Error:invalid liquidity");
        amount0 = (liquidity * reserveA) / _totalSupply;
        amount1 = (liquidity * reserveB) / _totalSupply;
        super._burn(msg.sender, liquidity);
        tokenA.transfer(msg.sender, amount0);
        tokenB.transfer(msg.sender, amount1);
        updateReserve(); 
        emit RemoveLiquidity(msg.sender, liquidity);
    }

    // 交易+滑点功能
    function sellToken(uint256 amount, address _token, uint256 output_MIN) public {
        require(_token == tokenA || _token == tokenB, "Error: incorrect address");
        if(_token == tokenA) {
            uint256 reserveA = tokenA.balanceOf(address(this));
            uint256 reserveB = tokenB.balanceOf(address(this));
            uint256 outputTokenBAmount = getInputPrice(amount, reserveA, reserveB);
            require(output_MIN >= outputToken1Amount, "incorrect amount");
            require(tokenA.transferFrom(msg.sender, address(this), amount), "tokenA transfer failed");
            require(tokenB.transfer(msg.sender, outputTokenBAmount), "tokenB transfer failed");
        } else {
            uint256 reserveA = tokenA.balanceOf(address(this)); 
            uint256 reserveB = tokenB.balanceOf(address(this));
            uint256 outputTokenAAmount = getInputPrice(amount, reserveB, reserveA);
            require(output_MIN >= outputTokenAAmount, "incorrect amount");
            require(tokenA.transfer(msg.sender, outputTokenAAmount), "tokenA transfer failed");
            require(tokenB.transferFrom(msg.sender, address(this), amount), "tokenB transfer failed");
        }
    }
   
    function buyToken(uint256 amount, address _token, uint256 input_MAX) public {
        require(_token == tokenA || _token == tokenB, "Error: incorrect address !");
        if(_token == tokenA) {
            uint256 reserveA = tokenA.balanceOf(address(this));
            uint256 reserveB = tokenB.balanceOf(address(this));
            uint256 inputTokenBAmount = getOutputPrice(amount, reserveB, reserveA);
            require(input_MAX >= inputTokenBAmount, "incorrect amount");
            require(tokenA.transfer(msg.sender, amount), "tokenB transfer failed");
            require(tokenB.transferFrom(msg.sender, address(this), inputTokenBAmount), "tokenA transfer failed");
        } else {
            uint256 reserveA = tokenA.balanceOf(address(this));
            uint256 reserveB = tokenB.balanceOf(address(this));
            uint256 inputTokenAAmount = getOutputPrice(amount, reserveA, reserveB);
            require(input_MAX >= inputTokenAAmount, "incorrect amount");
            require(tokenA.transferFrom(msg.sender, address(this), inputTokenAAmount), "tokenA transfer failed");
            require(tokenB.transfer(msg.sender, amount), "tokenB transfer failed");
        }
    }

    // 千分之三手续费
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns(uint256) {
        require(input_reserve > 0 && output_reserve > 0);
        uint256 input_amount_with_fee = input_amount * 997;
        uint256 numerator = input_amount_with_fee * output_reserve;
        uint256 denominator = (input_reserve * 1000) + input_amount_with_fee;
        return numerator / denominator;
    }

    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public pure returns(uint256) {
        require(input_reserve > 0 && output_reserve > 0);
        uint256 numerator = input_reserve * output_amount * 1000;
        uint256 denominator = (output_reserve - output_amount) * 997;
        return numerator / denominator + 1;
    }
}
