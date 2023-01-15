// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./FT.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//实验目的
// 熟练掌握ERC20标准，熟悉基于xy=k的AMM实现原理，
// 能实现增加/移除流动性，实现多个token的swap

contract Exchange is FT {
    // using SafeMath for uint256;
    address public tokenAddress;
    
    //LP, 即Liquidity Providers
    constructor(address _token) ERC20("LPtoken", "LP") {
        require(_token != address(0), "null address");
        tokenAddress = _token;
    }  

    //返回合约持有token数量
    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    //增加流动性
    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint tokenReserve = getReserve();
        ERC20 token = ERC20(tokenAddress);

        //如果token数为空
        if(tokenReserve == 0) {
            //转移
            token.transferFrom(msg.sender, address(this), _amount);

            //因为第一次添加，流动性直接等于ethBalance
            //并铸造LPtoken
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            //如果不为空
            //根据比例确定token数量

            //ethReverse = 当前的ethBalance减去用户在当前addLiquidity调用中发送的ether值
            uint ethReserve =  ethBalance - msg.value;

            //tokenAmount / tokenReverse = msg.value / ethReverse
            uint tokenAmount = (msg.value * tokenReserve)/(ethReserve);

            require(_amount >= tokenAmount, "Amount of tokens sent is less than the minimum tokens required");
            token.transferFrom(msg.sender, address(this), tokenAmount);
            
            //发送的LPtoken数应与用户添加的ether流动性成正比
            //liquidity / totalSupply = msg.value / ethReverse
            liquidity = (totalSupply() * msg.value)/ ethReserve;

            _mint(msg.sender, liquidity);
        }
         return liquidity;
    }

    //移除流动性
    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "_amount should be greater than zero");

        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();

        //返回的eth/token数基于比例
        //ethAmount / ethRever = _amount / _totalSupply
        uint ethAmount = (ethReserve * _amount)/ _totalSupply;

        //tokenAmount / getReserve() = _amount / _totalSupply
        uint tokenAmount = (getReserve() * _amount)/ _totalSupply;

        //删除已发送的LPtoken
        _burn(msg.sender, _amount);

        //eth/token转移到合约
        payable(msg.sender).transfer(ethAmount);
        ERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    //滑点是指预期交易价格和实际成交价格之间的差值
    //滑点百分比是兑换量占用于兑换的资产储备量的百分比
    //参考资料：https://blog.csdn.net/TokenInsight/article/details/110507838?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522167336061516800192267647%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fall.%2522%257D&request_id=167336061516800192267647&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~all~first_rank_ecpm_v1~rank_v31_ecpm-7-110507838-null-null.142^v70^control,201^v4^add_ask&utm_term=%E6%BB%91%E7%82%B9%E8%AE%A1%E7%AE%97&spm=1018.2226.3001.4187

    //实现手续费功能，获取返回给用户的token数量
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

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

    //eth交易为token
    function ethTotoken(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();

        //调用getAmountOfTokens()返回给用户的token数
        //注意这里要减去msg.value
        //因为address(this).balance已经包含了用户发送的value
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "wrong output amount");

        ERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }    

    //token交易为eth
    function tokenToEth(uint256 _tokensSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();

        //调用getAmountOfTokens()返回给用户的eth数
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "wrong output amount");

        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        
        payable(msg.sender).transfer(ethBought);
    }
}



