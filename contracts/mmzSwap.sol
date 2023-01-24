// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    实验内容
    1. 增加/移出流动性（完成）
    2. 交易功能（完成）
    3. 实现手续费功能，千分之三手续费（完成）
    4. 实现滑点功能（完成）
    5. 实现部署脚本（完成）
*/
contract LP is ERC20 {
    address public factory;
    address public Token0;
    address public Token1;
    mapping(address => uint256) balances;
    uint256 public totalsupply;
    uint256 reserve0;
    uint256 reserve1;

    constructor(address _token0, address _token1) ERC20("MMZ", "mmz") {
        Token0 = _token0;
        Token1 = _token1;
    }

    function updateRserve() internal returns(bool){
        reserve0 = ERC20(Token0).balanceOf(address(this));
        reserve1 = ERC20(Token1).balanceOf(address(this));
        return true;
    }

    /* 增加流动性
     * min_liquidity: 用户期望的LP代币数量
     * max_tokens: 用户想要提供的最大代币量
     * _token: 代币地址
     * inputAmount: 投入的代币数量
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, address _token, uint256 inputAmount) public payable {
        require(max_tokens > 0, "Error: max_tokens must > 0");
        require(_token == Token0 || _token == Token1, "Error: incorrect token address");
        uint256 totalLiquidity = totalsupply;
        if(totalLiquidity > 0) {
            if(_token == Token0) {
                uint256 token1_inputAmount = inputAmount * reserve1 / reserve0 + 1; //需要存入的token1数量
                uint256 liquidity_minted = inputAmount * totalLiquidity / reserve0; //增加的流动性
                require(max_tokens >= token1_inputAmount);
                require(liquidity_minted >= min_liquidity);
                balances[msg.sender] += liquidity_minted;
                totalsupply = totalLiquidity + liquidity_minted;
                require(ERC20(Token0).transferFrom(msg.sender, address(this), inputAmount), "Token0 transfer failed");
                require(ERC20(Token1).transferFrom(msg.sender, address(this), token1_inputAmount), "Token1 transfer failed");
            } else {
                uint256 token0_reserve = ERC20(Token0).balanceOf(address(this)); //池子剩余的token0数量
                uint256 token1_reserve = ERC20(Token1).balanceOf(address(this)); //池子剩余的token1数量
                uint256 token0_inputAmount = inputAmount * token0_reserve / token1_reserve + 1; //需要存入的token0数量
                uint256 liquidity_minted = inputAmount * totalLiquidity / token1_reserve; //增加的流动性
                require(max_tokens >= token0_inputAmount);
                require(liquidity_minted >= min_liquidity);
                balances[msg.sender] += liquidity_minted;
                totalsupply = totalLiquidity + liquidity_minted;
                require(ERC20(Token0).transferFrom(msg.sender, address(this), token0_inputAmount), "Token0 transfer failed");
                require(ERC20(Token1).transferFrom(msg.sender, address(this), inputAmount), "Token1 transfer failed");
            }
        } else {
            if(_token == Token0) {
                uint256 token1_inputAmount = max_tokens;
                uint256 initial_liquidity = inputAmount;
                balances[msg.sender] += initial_liquidity;
                totalsupply = totalLiquidity + initial_liquidity;
                require(ERC20(Token0).transferFrom(msg.sender, address(this), inputAmount), "Token0 transfer failed");
                require(ERC20(Token1).transferFrom(msg.sender, address(this), token1_inputAmount), "Token1 transfer failed");
            } else {
                uint256 token0_inputAmount = max_tokens;
                uint256 initial_liquidity = inputAmount;
                balances[msg.sender] += initial_liquidity;
                totalsupply = totalLiquidity + initial_liquidity;
                require(ERC20(Token0).transferFrom(msg.sender, address(this), token0_inputAmount), "Token0 transfer failed");
                require(ERC20(Token1).transferFrom(msg.sender, address(this), inputAmount), "Token1 transfer failed");
            }    
        }

    }



    /* 移除流动性
     * amount: 用户想取走的LPtoken数量
     * min_token0: 最小取走的token0数量
     * min_token1: 最小取走的token1数量
     */
    function removeLiquidity(uint256 amount, uint256 min_token0, uint256 min_token1) public {
        uint256 totalLiquidity = totalsupply;
        require(totalLiquidity > 0);
        require(amount < balances[msg.sender]);
        uint256 token0_reserve = ERC20(Token0).balanceOf(address(this)); //池子里token0的数量
        uint256 token1_reserve = ERC20(Token1).balanceOf(address(this)); //池子里token1的数量
        uint256 token0_amount = amount * token0_reserve / totalLiquidity; //返回token0的数量
        uint256 token1_amount = amount * token1_reserve / totalLiquidity; //返回token1的数量
        require(token0_amount > min_token0);
        require(token1_amount > min_token1);
        balances[msg.sender] -= amount;
        totalsupply = totalLiquidity - amount;
        require(ERC20(Token0).transfer(msg.sender, token0_amount));
        require(ERC20(Token1).transfer(msg.sender, token1_amount));
    }
    // 交易+滑点功能
    /*
     * amount: 用户可以售卖的token数量
     * _token: 用户售卖的token类型（Token0 / Token1）
     * 通过getInputPrice函数可以计算出我们手上的Token0/Token1可以兑换多少的Token1/Token0
     */
    function sellToken(uint256 amount, address _token, uint256 output_MIN) public {
        require(_token == Token0 || _token == Token1, "Error: incorrect address !");
        if(_token == Token0) {
            uint256 token0_reserve = ERC20(Token0).balanceOf(address(this));
            uint256 token1_reserve = ERC20(Token1).balanceOf(address(this));
            uint256 outputToken1Amount = getInputPrice(amount, token0_reserve, token1_reserve);
            require(output_MIN >= outputToken1Amount, "incorrect amount");
            require(ERC20(Token0).transferFrom(msg.sender, address(this), amount), "Token0 transfer failed");
            require(ERC20(Token1).transfer(msg.sender, outputToken1Amount), "Token1 transfer failed");
        } else {
            uint256 token0_reserve = ERC20(Token0).balanceOf(address(this)); 
            uint256 token1_reserve = ERC20(Token1).balanceOf(address(this));
            uint256 outputToken0Amount = getInputPrice(amount, token1_reserve, token0_reserve);
            require(output_MIN >= outputToken0Amount, "incorrect amount");
            require(ERC20(Token0).transfer(msg.sender, outputToken0Amount), "Token0 transfer failed");
            require(ERC20(Token1).transferFrom(msg.sender, address(this), amount), "Token1 transfer failed");
        }
    }
    /*
     * amount: 用户想要购买的的token数量
     * _token: 用户购买的token类型（Token0 / Token1）
     * 通过getOutputPrice函数可以计算出我们想要购买amount数量的Token0/Token1需要支付多少的Token1/Token0
     */
    function buyToken(uint256 amount, address _token, uint256 input_MAX) public {
        require(_token == Token0 || _token == Token1, "Error: incorrect address !");
        if(_token == Token0) {
            uint256 token0_reserve = ERC20(Token0).balanceOf(address(this));
            uint256 token1_reserve = ERC20(Token1).balanceOf(address(this));
            uint256 inputToken1Amount = getOutputPrice(amount, token1_reserve, token0_reserve);
            require(input_MAX >= inputToken1Amount, "incorrect amount");
            require(ERC20(Token0).transfer(msg.sender, amount), "Token1 transfer failed");
            require(ERC20(Token1).transferFrom(msg.sender, address(this), inputToken1Amount), "Token0 transfer failed");
        } else {
            uint256 token0_reserve = ERC20(Token0).balanceOf(address(this));
            uint256 token1_reserve = ERC20(Token1).balanceOf(address(this));
            uint256 inputToken0Amount = getOutputPrice(amount, token0_reserve, token1_reserve);
            require(input_MAX >= inputToken0Amount, "incorrect amount");
            require(ERC20(Token0).transferFrom(msg.sender, address(this), inputToken0Amount), "Token0 transfer failed");
            require(ERC20(Token1).transfer(msg.sender, amount), "Token1 transfer failed");
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