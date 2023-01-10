pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FT.sol";

//实验目的
// 熟练掌握ERC20标准，熟悉基于xy=k的AMM实现原理，
// 能实现增加/移除流动性，实现多个token的swap

contract Exchange is FT{
    // using SafeMath for uint256;
    address public tokenAddress;
  
    //返回合约持有token数量
    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    constructor(address _token) FT("LPtoken", "LP") {
        require(_token != address(0), "Token address passed is a null address");
        tokenAddress = _token;
    }

    //增加流动性
    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint tokenReserve = getReserve();
        ERC20 token = ERC20(tokenAddress);
        //如果token数为空
        if(tokenReserve == 0) {
            //将token地址从用户账户转移到合约
            token.transferFrom(msg.sender, address(this), _amount);
            //第一次添加，直接相等
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            //如果不为空
            uint ethReserve =  ethBalance - msg.value;
            //比例应始终不变，以便在增加流动性时不会对价格产生重大影响
            uint tokenAmount = (msg.value * tokenReserve)/(ethReserve);
            require(_amount >= tokenAmount, "Amount of tokens sent is less than the minimum tokens required");
            token.transferFrom(msg.sender, address(this), tokenAmount);
            //将发送的LPtoken数应与用户添加的ether成正比
            liquidity = (totalSupply() * msg.value)/ ethReserve;
            _mint(msg.sender, liquidity);
        }
         return liquidity;
    }

    //移除流动性
    function removeLiquidity(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "_amount should be greater than zero");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint ethAmount = (ethReserve * _amount)/ _totalSupply;
        uint tokenAmount = (getReserve() * _amount)/ _totalSupply;
        //移除流动性
        _burn(msg.sender, _amount);
        //eth转移到合约
        payable(msg.sender).transfer(ethAmount);
        ERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    //实现手续费功能，获取返回给用户的token数量
    //滑点是指预期交易价格和实际成交价格之间的差值
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        //收取千分之三手续费
        // inputAmountWithFee = (inputAmount - ((inputAmount)*3/1000)) = ((inputAmount)*997)/1000
        uint256 inputAmountWithFee = inputAmount * 997;
        // xy = k
        // (x + Δx) * (y - Δy) = x * y
        // Δy = (y * Δx) / (x + Δx)
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }

    //eth交易为token
    function ethTotoken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        require(tokensBought >= _minTokens, "wrong output amount");
        ERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }    

    //token交易为eth
    function tokenToEth(uint _tokensSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();
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



