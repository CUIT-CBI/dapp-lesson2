// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20{
  address public tokenAddress;

    constructor(address _tokenAddress)ERC20("sam" , "SAM"){
      require(_tokenAddress != address(0),"invalid address");
      tokenAddress=_tokenAddress;

    }



  function addLiquidity(uint256 _amount)public payable returns(uint256){


    if (getReserve()==0) {


      IERC20 token= IERC20(tokenAddress);
      token.transferFrom(msg.sender, address(this), _amount);

       uint256 liquidity = address(this).balance;

      _mint(msg.sender, liquidity);
      return liquidity;
    }else{
      uint256 ethReserve = address(this).balance - msg.value;
      uint256 tokenReserve = getReserve();
      uint256 tokenAmount  = (msg.value * tokenReserve)/ethReserve;
      require(tokenAmount<=_amount,"invalid amount");
      IERC20 token = IERC20(tokenAddress);
      token.transferFrom(msg.sender, address(this), tokenAmount);


      uint256 liquidity = (totalSupply() * msg.value)/ethReserve;
      _mint(msg.sender, liquidity);
      return liquidity;
    } 
    
  }



function removeLiquidity(uint256 _amount)public  returns(uint256,uint256){
    require(_amount>0,"invalid amount!");
    uint256 ethAmount =address(this).balance *  _amount / totalSupply();
    uint256 tokenAmount =getReserve() *  _amount / totalSupply();

    _burn(msg.sender, _amount);
    payable(msg.sender).transfer(ethAmount);
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    return(ethAmount,tokenAmount);
  }

  function getReserve() public view returns (uint256){
    return IERC20(tokenAddress).balanceOf(address(this));
  }



  function getAmount(uint256 inputAmount,uint256 inputReserve, uint256 outputReserve)private pure returns(uint256){
    require(inputReserve > 0&&outputReserve > 0,"invalid reserves");

    uint256 inputAmountWithFee = (inputAmount*3)/1000;
    uint256 inputAmountWithoutFee = inputAmount-inputAmountWithFee;
    uint256 numerator = inputAmountWithoutFee*outputReserve;
    uint256 denominator = inputAmountWithoutFee + inputReserve  ;
    return numerator/denominator;
  }



    function getTokenAmount(uint256 _ethSold)public view returns(uint256){
    require(_ethSold > 0,"invalid");
    uint256 tokenReserve = getReserve();
    return getAmount(_ethSold, address(this).balance, tokenReserve);
  }


    function getEtherAmount(uint256 _tokenSold)public view returns(uint256){
    require(_tokenSold > 0,"invalid");
    uint256 tokenReserve = getReserve();
    return getAmount(_tokenSold, tokenReserve, address(this).balance);
  }


  function ethToTokenSwap(uint256 _minTokens)public payable{
    uint256 tokenReserve = getReserve();
    uint256 tokenBought = getAmount(msg.value, address(this).balance-msg.value, tokenReserve);
    
    require(tokenBought>=_minTokens,"insuffcient output");
    IERC20(tokenAddress).transfer(msg.sender, tokenBought);
  }



  function TokenToethSwap(uint256 _tokenSold,uint256 _minEth)public {
    uint256 tokenReserve = getReserve();
    uint256 ethBought = getAmount(_tokenSold, tokenReserve,address(this).balance);
    
    require(ethBought>=_minEth,"insuffcient output");
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
    payable(msg.sender).transfer(ethBought);
  }



  function CaculateEthSlippage(uint256 _ethSold)public view returns(uint256){
    return _ethSold/(getReserve()+_ethSold);
  }

  function CaculateTokenSlippage(uint _tokenSold)public view returns(uint256){
    return _tokenSold/(address(this).balance+_tokenSold);
  }
}
