pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FT.sol";
/**
需要完成的功能：
1. 增加/移出流动性 30分
2. 交易功能 30分
3. 实现手续费功能，千分之三手续费 10分
4. 实现滑点功能 15分
5. 实现部署脚本 15分
 */
contract SwapDemo is FT{
    //合约地址
    address public tokenAddress;

    //创建token
    constructor(address _token) FT("YYToken","YY"){
        require(_token != address(0), "fault!---1");
        tokenAddress = _token;
    }

    //增加流动性
    function addStream(uint _amount)public payable returns (uint) {
        uint tokenReserve = getReserve();
        uint ethReserve = address(this).balance;
        IERC20 token = IERC20(tokenAddress);
        uint res;
        if(tokenReserve==0){
            //为0；就将token地址从用户账户=>合约
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            //增加流动性证明
            res = ethReserve;
            _mint(msg.sender,res);
        }else{
            //不为空，计算价格变化
            unit ethReserve2 = ethReserve-msg.value;
            unit tokenAmount = (msg.value * tokenReserve) / ethReserve2;
            require(_amount >= tokenAmount, "fault!----2");
             token.transferFrom(msg.sender, address(this), tokenAmount);
             res = (totalSupply() * msg.value)/ ethReserve2;
             _mint(msg.sender, liquidity);

        }
        return res;
    }
    //获得token余额
    function  getReserve() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    } 
    //移除流动性
    function removeStream(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "fault!-----3");
        uint totalSupply = totalSupply();
        uint ethReserve = address(this).balance;
        uint ethAmount = (ethReserve * _amount)/ totalSupply;
        uint tokenAmount = (getReserve() * _amount)/ totalSupply;
        //移除流动性
        _burn(msg.sender, _amount);
        //eth转移到合约
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }
    // 交易功能---> ETH换Token
    function ethToToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        require(tokensBought >= _minTokens, "fault!----4");
        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }    
    //扣除手续费
    function getAmount(uint256 inputAmount,uint256 inputReserve,uint256 outputReserve) 
    private 
    pure 
    returns (uint256) 
    {
        require(inputReserve > 0 && outputReserve > 0, "fault!----5");
        //千分之三的手续费
        uint256 inputAmountFee = inputAmount * 997;
        uint256 numerator = inputAmountFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountFee;

        return numerator / denominator;
    }
    //交易功能--->TOKEN换eth
    function tokenToEth(uint256 _tokensSold, uint256 _minEth) 
    public 
    payable
    {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokensSold,tokenReserve,address(this).balance);

        require(ethBought >= _minEth, "fault!----6");

        IERC20(tokenAddress).transferFrom(msg.sender,address(this),_tokensSold);
        payable(msg.sender).transfer(ethBought);
    }
}

