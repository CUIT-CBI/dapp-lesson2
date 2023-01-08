// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FT.sol";


//类似UniswapV1 => 只有ERC20/ETH交易对(颁发的LPtoken使用到了FT合约)
  //此合约功能实现:
  //1.增加/移除流动性 => 完成
  //2.交易功能 => 完成
  //3.手续费功能，千分之三手续费 => 完成
  //4.滑点功能 => 完成
  

  //加分项 => 未做


//此合约功能类似交易所合约
contract Exchange is FT{
    //创建ERC20/ET交易对的代币合约地址
    address public tokenAddress;

    //将FT换成ERC20是一样的 => 目的:创建LPtoken
    constructor(address _token) FT("WZ-Uniswap", "wz")
    {
        require(_token != address(0), "constructor:insufficient address!");
        tokenAddress = _token;
    }

    //提供流动性 => 实质:token和ETH先后转入此合约
    function addLiquidity(uint256 _tokenAmount, uint256 deadline) 
    public 
    payable 
    returns (uint256)
    {   
        require(block.timestamp <= deadline, "addLiquidity: Trade out of time");
        //池子为空=>新交易所
        if (getReserve() == 0){

        //将token从代币合约转移到此(交易所)合约 => 我比较喜欢将这个合约视为交易所合约
          //IERC20(tokenAddress) => 符合ERC20接口标准的代币均可创建和ETH的交易对
        IERC20 token = IERC20(tokenAddress);  
        token.transferFrom(msg.sender, address(this), _tokenAmount);
         
        //给msg.sender添加流动性证明,LPtoken计算
        uint256 liquidity = address(this).balance;
        _mint(msg.sender, liquidity);
        return liquidity;
        //池子不为空 => 有一定流动性
        }else {
            //计算移除前后的价格比例变化:P = x/y
            uint256 eth_reserve = address(this).balance - msg.value;
            uint256 token_reserve = getReserve();
            uint256 token_amount = (msg.value * token_reserve) / eth_reserve;
            //如果用户存入金额小于此金额，抛出错误
            require(_tokenAmount >= token_amount, "addLiquidity: insufficient token _amount");

            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), token_amount);
            
            //LPtoken计算 => 与存入的以太币数量成比例铸造
            uint256 liquidity =(msg.value * totalSupply()) / eth_reserve;
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    //移除流动性 => 实质：token和ETH同时被移除
    function removeLiquidity(uint256 _amount, uint256 deadline) 
    public 
    returns (uint256, uint256) 
    {
        require(block.timestamp <= deadline, "addLiquidity: Trade out of time");
        require(_amount > 0, "removeLiquidity: invalid _amount");
        //因为颁发代币是与以太币数量成比例的，所以可以根据LP代币份额移除流动性
        uint256 eth_amount = (address(this).balance * _amount) / totalSupply();
        uint256 token_amount = (getReserve() * _amount) / totalSupply();
        
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(eth_amount);
        IERC20(tokenAddress).transfer(msg.sender, token_amount);

        return (eth_amount, token_amount);
}
    
    //交易1:ETH换Token => 可进一步封装
    function ethToToken(uint256 _minTokens, address recipient) 
    public 
    payable 
    {
        uint256 token_reserve = getReserve();
        //去除0.3%手续费
        uint256 tokensBought = getAmount(msg.value,address(this).balance - msg.value,token_reserve);
    
        require(tokensBought >= _minTokens, "ethToToken: insufficient output _amount");
        IERC20(tokenAddress).transfer(recipient, tokensBought);
   }
 
    //交易2:token换ETH => 可进一步封装
    function tokenToEth(uint256 _tokensSold, uint256 _minEth) 
    public 
    payable
    {
        uint256 tokenReserve = getReserve();
        //去除0.3%手续费
        uint256 ethBought = getAmount(_tokensSold,tokenReserve,address(this).balance);

        require(ethBought >= _minEth, "insufficient output amount");

        IERC20(tokenAddress).transferFrom(msg.sender,address(this),_tokensSold);
        payable(msg.sender).transfer(ethBought);
    }

    //计算去除手续费交换后的token或者ETH
      //原理:(x+Δx)(y−Δy)=xy
    function getAmount(uint256 input_amount,uint256 input_reserve,uint256 output_reserve) 
    private 
    pure 
    returns (uint256) 
    {
        require(input_reserve > 0 && output_reserve > 0, "get_amount: invalid _reserves");
       
        //0.3%的手续费 => solidity不支持浮点数运算=>放大计算
        uint256 input_amountFee = input_amount * 997;
        uint256 numerator = input_amountFee * output_reserve;
        uint256 denominator = (input_reserve * 1000) + input_amountFee;

        return numerator / denominator;
    }

    //功能函数:充当价格预言机的作用
    function getTokenAmount(uint256 _ethSold) 
    public 
    view 
    returns (uint256) 
    {
        require(_ethSold > 0, "ethSold is too small");

        uint256 tokenReserve = getReserve();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    //功能函数:充当价格预言机的作用
    function getEthReverse(uint256 _tokenSold) 
    public 
    view 
    returns (uint256) 
    {
        require(_tokenSold > 0, "tokenSold is too small");

        uint256 tokenReserve = getReserve();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    //功能函数:返回token余额
    function getReserve() 
    public 
    view 
    returns (uint256) 
    {
        //返回 该交易所 所拥有的 在某个交易对中 ERC20代币的数量
        return IERC20(tokenAddress).balanceOf(address(this));
    }

}

//参考学习:
  //1.https://iondex.github.io/2021/07/13/uniswap-v1-source-code/
  //2.https://github.com/Jeiwan/zuniswap/