// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract FT is ERC20{
  address public tokenAddress;
    constructor(address _tokenAddress)ERC20("hjy" , "hjy1"){
      require(_tokenAddress != address(0),"invalid address");
      tokenAddress=_tokenAddress;
    }
    //增加流动性
  function addliquidity(uint256 _amount)public payable returns(uint256){
    //当前池子中不具有流动性
    if (getReserve()==0) {
      //将提供流动性的用户的钱转入合约中
      IERC20 token= IERC20(tokenAddress);
      token.transferFrom(msg.sender, address(this), _amount);
       uint256 liquidity = address(this).balance;
      _mint(msg.sender, liquidity);
      return liquidity;
    }else{
      //池子中的
      uint256 ethReserve = address(this).balance - msg.value;//计算value进入之前池子中的eth数量
      uint256 tokenReserve = getReserve();//获取当前池子中的token数量
      uint256 tokenAmount  = (msg.value * tokenReserve)/ethReserve;
      require(tokenAmount<=_amount,"invalid amount");
      IERC20 token = IERC20(tokenAddress);
      token.transferFrom(msg.sender, address(this), tokenAmount);
      //流动性计算
      uint256 liquidity = (totalSupply() * msg.value)/ethReserve;
      _mint(msg.sender, liquidity);
      return liquidity;
    } 

  }
//移除流动性
function deLiquidity(uint256 _amount)public  returns(uint256,uint256){
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
  //对手续费的计算以及计算汇率
  function getAmount(uint256 inputAmount,uint256 inputReserve, uint256 outputReserve)private pure returns(uint256){
    require(inputReserve > 0&&outputReserve > 0,"invalid reserves");
    uint256 inputAmountWithoutFree = (inputAmount*997)/1000;
    uint256 nume = inputAmountWithoutFree*outputReserve;
    uint256 deno = inputAmountWithoutFree + inputReserve  ;
    return nume/deno;
  }

  //当前eth能换多少token
    function getTokenAmount(uint256 _ethSell)public view returns(uint256){
    require(_ethSell > 0,"invalid");
    uint256 tokenReserve = getReserve();
    return getAmount(_ethSell, address(this).balance, tokenReserve);
  }
  //当前token能换多少eth
    function getEtherAmount(uint256 _tokenSell)public view returns(uint256){
    require(_tokenSell > 0,"invalid");
    uint256 tokenReserve = getReserve();
    return getAmount(_tokenSell, tokenReserve, address(this).balance);
  }
  //eth换取token
  function ethToTokenSwap(uint256 minTokens)public payable{
    uint256 tokenReserve = getReserve();
    uint256 tokenBought = getAmount(msg.value, address(this).balance-msg.value, tokenReserve);

    require(tokenBought>=minTokens,"insuffcient output");
    IERC20(tokenAddress).transfer(msg.sender, tokenBought);
  }
//token换取eth
  function TokenToethSwap(uint256 _tokenSell,uint256 _minEth)public {
    uint256 tokenReserve = getReserve();
    uint256 ethBought = getAmount(_tokenSell, tokenReserve,address(this).balance);

    require(ethBought>=_minEth,"insuffcient output");
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSell);
    payable(msg.sender).transfer(ethBought);
  }
  //滑点百分比计算
  function CaculateEthSlippage(uint256 _ethSell)public view returns(uint256){
    return _ethSell/(getReserve()+_ethSell);
  }

  function CaculateTokenSlippage(uint _tokenSold)public view returns(uint256){
    return _tokenSold/(address(this).balance+_tokenSold);
  }
}
