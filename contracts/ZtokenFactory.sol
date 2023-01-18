// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FT.sol";

// 参考地址https://github1s.com/finndayton/DEX/blob/HEAD/contracts/exchange.sol
contract TokenExchange {
    using SafeMath for uint;
    address public admin;

    //交易所的流动性池pool
    mapping(address => uint) public token_reserves;
    mapping(address => uint) public eth_reserves;
    
    uint public initial_liquidity = 0;
    uint private multiplier = 10**18;
    mapping(address => mapping(address => uint)) public user_token_balance;
    mapping(address => uint) public eth_contributed;//记录用户投入多少eth在这个池子里
    mapping(address => uint) public k;//x * y = k
    mapping(address => address) public ZYXtoken;

    event AddLiquidity(address from, uint amount);
    event RemoveLiquidity(address to, uint amount);
    event Received(address from, uint amountETH);
    event CreatePool(string message, uint eth_reserves, uint token_reserves, uint k);

    constructor() {
        admin = msg.sender;
    }

    modifier OnlyAdmin {
        require(msg.sender == admin, "Only admin can use this function!");
        _;
    }

    //接收 ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    fallback() external payable{
        emit Received(msg.sender, msg.value);
    }
    function sqrt(uint256 y) internal pure returns (uint256 z) {
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
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        //z = x < y ? x : y;
        if(x<y){
           z=x;
        }else{
           z=y;
        }
    }
    //创建代币和eth之间的流动性池
    function createPool(address token,uint amountTokens) external payable OnlyAdmin {
        //确保池子还未被创立
        require (token_reserves[token] == 0, "Token reserves was not 0.");
        require (eth_reserves[token] == 0, "ETH reserves was not 0.");

        //确保token已发送且不等于0
        require (msg.value > 0, "Need ETH to create pool.");
        require (amountTokens > 0, "Need tokens to create pool.");

        //添加初始流动性
        IERC20(token).transferFrom(msg.sender, address(this), amountTokens);
        eth_reserves[token] = msg.value;
        token_reserves[token] = amountTokens;
        
        //初始化k
        k[token] = eth_reserves[token].mul(token_reserves[token]);

        //初始化 ZYX token
        address ZYX = address(new FT("ZYXtoken", "ZYX"));
        ZYXtoken[token] = ZYX;

        emit CreatePool("log data from createPool", eth_reserves[token], token_reserves[token], k[token]);

        //用户的个人流动性权益
        eth_contributed[msg.sender] = msg.value;
        user_token_balance[token][msg.sender] = amountTokens;
    }

    //铸造 ZYX token
    function mintZYX(address token, address to, uint amount0, uint amount1) internal returns (uint liquidity) {

        uint256 _totalSupply = IERC20(ZYXtoken[token]).totalSupply();
        if (_totalSupply == 0) {
            liquidity = sqrt(amount0.mul(amount1));
        } else {
            liquidity = min(amount0.mul(_totalSupply) / token_reserves[token], amount1.mul(_totalSupply) / eth_reserves[msg.sender]);
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        FT(ZYXtoken[token]).mint(to, liquidity);
    }

    //销毁 ZYX token
    function burnZYX(address token, address to) internal returns (uint amount0, uint amount1) {
        uint balance0 = user_token_balance[token][msg.sender];
        uint balance1 = eth_contributed[msg.sender];
        uint liquidity = IERC20(ZYXtoken[token]).balanceOf(address(msg.sender));

        //把用户zyx所占总zyx比例的token0和token1返还用户
        uint _totalSupply = IERC20(ZYXtoken[token]).totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');

        FT(ZYXtoken[token]).burn(liquidity);
        IERC20(token).transfer(to, amount0);
        (bool success, ) = payable(msg.sender).call{value:amount1}("");
        require(success, "Failed to send Ether in burn");
    }

    //计算 token 的价格price
    function priceToken(address token) public view returns (uint) {
        return (eth_reserves[token].mul(multiplier)).div(token_reserves[token]);
    }
    //计算 eth 的价格price
    function priceETH(address token) public view returns (uint) {
        require(eth_reserves[token] > 0, "eth_reserves must be greater than 0 (priceETH)");
        return (token_reserves[token].mul(multiplier)).div(eth_reserves[token]);
    }

    //添加流动性
    function addLiquidity(address token, uint minPriceEth, uint maxPriceEth) external payable {
        //确保价格在滑点范围内
        require(priceETH(token) > minPriceEth.mul(multiplier), "the price of eth has fallen too low to add liquidity");
        require(priceETH(token) < maxPriceEth.mul(multiplier), "the price of eth has risen too high to add liquidity");

        require(msg.value > 0, "provided eth amount was 0");

        //计算 token 价格
        uint new_tokens = (msg.value.mul(priceETH(token)).div(multiplier));
        require(IERC20(token).balanceOf(msg.sender) >= new_tokens, "sender does not posses enough FinnCoin");

        //将对应数量的 token 发送到池子
        IERC20(token).transferFrom(msg.sender, address(this), new_tokens);
        //增加池子中 token 和 eth 的储备数量
        token_reserves[token] = token_reserves[token].add(new_tokens);
        eth_reserves[token] = eth_reserves[token].add(msg.value);
        //更新 k 值
        k[token] = eth_reserves[token].mul(token_reserves[token]);
        //更新用户的个人流动性权益
        eth_contributed[msg.sender] = eth_contributed[msg.sender].add(msg.value);
        user_token_balance[token][msg.sender] = user_token_balance[token][msg.sender].add(new_tokens);
        //铸造 ZYX token
        mintZYX(token, msg.sender, new_tokens, msg.value);
        emit AddLiquidity(msg.sender, msg.value);

    }

    //移除流动性
    function removeLiquidity(address token, uint amountETH, uint minPriceEth, uint maxPriceEth) public payable {
        //确保价格在滑点范围内
        require(priceETH(token) > minPriceEth.mul(multiplier), "the price of eth has fallen too low to remove liquidity");
        require(priceETH(token) < maxPriceEth.mul(multiplier), "the price of eth has risen too high to remove liquidity");

        require(amountETH > 0, "ETH amount must be greater than 0");
        require (amountETH < eth_reserves[token], "Cannot withdraw all eth from the pool");

        require(amountETH <= eth_contributed[msg.sender], "User is not entitled to withdraw this many eth");

        //计算提取 ETH 所对应的 token 数量
        uint corresponding_tokens = (priceETH(token).mul(amountETH)).div(multiplier);

        //更新池中的存储和k值
        eth_reserves[token] = eth_reserves[token].sub(amountETH);
        token_reserves[token] = token_reserves[token].sub(corresponding_tokens);
        k[token] = eth_reserves[token].mul(token_reserves[token]);
        eth_contributed[msg.sender] = eth_contributed[msg.sender].sub(msg.value);
        user_token_balance[token][msg.sender] = user_token_balance[token][msg.sender].sub(corresponding_tokens);

        //发送 token 和 eth
        IERC20(token).transfer(msg.sender, corresponding_tokens);
        (bool success, ) = payable(msg.sender).call{value:amountETH}("");
        require(success, "Failed to send Ether in remove");
        
        //销毁ZYX
        burnZYX(token, msg.sender);
        emit RemoveLiquidity(msg.sender, amountETH);

    }

    //用户使用 token 交换 eth
    function swapTokensForETH(address token, uint amountTokens, uint maxEthPriceTolerated) external payable {
        //确保在滑点范围内
        require(priceETH(token) < maxEthPriceTolerated.mul(multiplier));
        require(IERC20(token).balanceOf(msg.sender) >= amountTokens);
        uint amount_eth = getAmount(amountTokens, token_reserves[token], eth_reserves[token]);
        require(amount_eth < eth_reserves[token], "Performing the swap");

        //将用于提现的token转到合约账户里
        IERC20(token).transferFrom(msg.sender, address(this), amountTokens);

        //将提出的eth转账到账户
        payable(msg.sender).transfer(amount_eth);
        token_reserves[token] = token_reserves[token].add(amountTokens);
        eth_reserves[token] = eth_reserves[token].sub(amount_eth);
        k[token] = token_reserves[token].mul(eth_reserves[token]);

    }

    //用户使用 eth 交换 token
    function swap(address token, uint maxTokenPriceTolerated) external payable {
        //确保在滑点范围内
        require(priceToken(token) < maxTokenPriceTolerated.mul(multiplier));
        uint tokens = getAmount(msg.value, eth_reserves[token], token_reserves[token]);
        require(tokens < token_reserves[token], "Performing the swap");

        //将提出的token转到用户地址
        IERC20(token).transfer(msg.sender, tokens);
        token_reserves[token] = token_reserves[token].sub(tokens);
        eth_reserves[token] = eth_reserves[token].add(msg.value);
        k[token] = token_reserves[token].mul(eth_reserves[token]);
    }
    
    //根据输入，计算扣除千分之三手续费后的输出
    function getAmount(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

}

