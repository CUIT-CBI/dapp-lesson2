// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract  Exchange is ERC20{
  address  public token1Address;
  address  public token2Address;

  // uint256  public token1Reserve;
  // uint256  public token2Reserve;
    constructor(address _token1Address,address _token2Address)ERC20("dyx" , "dfy"){
      require(_token1Address != address(0),"invalid address");
      require(_token1Address != address(0),"invalid address");
      token1Address=_token1Address; 
      token2Address=_token2Address; 
    }
    //流动性的增加与移除 
    //增加流动性 
  function addLiquidity(uint256 _amount1,uint256 _amount2)public  returns(uint256){
    //当前池子中不具有流动性
    uint256 token1Reserve;
    uint256 token2Reserve;
    (token1Reserve, token2Reserve) = getReserve();//获取当前池子中的token数量
    uint256 liquidity;
    if (token1Reserve==0&&token2Reserve==0) {
      //将提供流动性的用户的钱转入合约中
      IERC20 token1= IERC20(token1Address);
      IERC20 token2= IERC20(token2Address);
      token1.transferFrom(msg.sender, address(this), _amount1);
      token2.transferFrom(msg.sender, address(this), _amount2);
       //奖励
       liquidity = 10**5;
      _mint(msg.sender, liquidity);
      return liquidity;
    }else{
      uint256 mintokenReserve = min(token1Reserve+_amount1, token2Reserve+_amount2);
      if (mintokenReserve==uint256(1)){
          uint256 token1Amount = _amount2*token1Reserve/token2Reserve;
          IERC20(token1Address).transferFrom(msg.sender, address(this), token1Amount);
          IERC20(token2Address).transferFrom(msg.sender, address(this), _amount2);
          liquidity=totalSupply()*_amount2/token2Reserve;
          _mint(msg.sender,liquidity);
      }else{
        uint256 token2Amount = _amount1*token2Reserve/token1Reserve;
        IERC20(token2Address).transferFrom(msg.sender, address(this), token2Amount);
        IERC20(token1Address).transferFrom(msg.sender, address(this), _amount1);
        liquidity=totalSupply()*_amount1/token1Reserve;
        _mint(msg.sender,liquidity);
      } 
    }
    
    return liquidity;
  }
//移除流动性 
function removeLiquidity(uint256 liquidity)public returns(uint256,uint256){
    require(liquidity>0,"invalid");
    assert(transfer(address(this), liquidity));
    uint256 token1Reserve;
    uint256 token2Reserve;
    (token1Reserve, token2Reserve) = getReserve();//获取当前池子中的token数量
    uint256 token1Amount =liquidity *   token1Reserve/ totalSupply();
    uint256 token2Amount =liquidity *  token2Reserve / totalSupply();

    _burn(msg.sender, liquidity);
    assert(IERC20(token1Address).transfer(msg.sender, token1Amount));
    assert(IERC20(token2Address).transfer(msg.sender, token2Amount));
    return(token1Amount,token2Amount);
  }

  function getReserve() public view returns (uint256,uint256){
    return (IERC20(token1Address).balanceOf(address(this)),IERC20(token2Address).balanceOf(address(this)));
  }
  // 对手续费的计算以及计算汇率
  function  getAmount(uint256 inputAmount,uint256 inputReserve, uint256 outputReserve)private pure returns(uint256){
    require( inputReserve > 0&&outputReserve > 0,"invalid reserves");

    uint256  inputAmountWithFee = (inputAmount*3)/1000;
    uint256  inputAmountWithoutFee = inputAmount-inputAmountWithFee;
    uint256  numerator = inputAmountWithoutFee*outputReserve;
    uint256  denominator = inputAmountWithoutFee + inputReserve  ;
    return  numerator/denominator;
  }
  // 交易功能
  // 获取当前token1能换多少token2
  function  getToken1Amount(uint256 _token1Sold)public view returns(uint256){
    require(_token1Sold > 0,"invalid");
    uint256 token1Reserve;
    uint256 token2Reserve;
     (token1Reserve, token2Reserve) = getReserve();
    return getAmount(_token1Sold, token1Reserve, token2Reserve);
  }
  //获取当前token能换多少eth
    function getEtherAmount(uint256 _token2Sold)public view returns(uint256){
    require(_token2Sold > 0,"invalid");
     uint256 token1Reserve;
    uint256 token2Reserve;
     (token1Reserve, token2Reserve) = getReserve();
    return getAmount(_token2Sold, token2Reserve, token1Reserve);
  }
  //实现token2换取token1(交易)
  function  token2ToToken1Swap(uint256 _mintokens,uint256 _token2Sold)public  returns(uint256){
    uint256 token1Reserve;
    uint256 token2Reserve;
    (token1Reserve,token2Reserve) = getReserve();
    uint256 token1Bought = getAmount(_token2Sold, token2Reserve, token1Reserve);
    //uint _minTokens = token1Bought-token1Bought*CaculateToken1Slippage(token1Bought);//滑点计算
    require(token1Bought>=_mintokens,"insuffcient output");
    IERC20(token2Address).transferFrom(msg.sender, address(this), token1Bought);
    this.transfer(msg.sender, token1Bought);
    return token1Bought;
  }
//实现token1换取token2
  function Token1ToToken2Swap(uint256 _mintokens,uint256 _token1Sold)public {
   uint256 token1Reserve;
    uint256 token2Reserve;
    (token1Reserve,token2Reserve) = getReserve();
    uint256 token2Bought = getAmount(_token1Sold, token1Reserve,token2Reserve);
    // uint256 _mintoken = token2Bought-token2Bought*CaculateToken2Slippage(token2Bought);//滑点计算公式
    require(token2Bought>=_mintokens,"insuffcient output");
    IERC20(token1Address).transferFrom(msg.sender, address(this), _token1Sold);
    this.transfer(msg.sender, token2Bought);
  }
  // //滑点百分比计算
  // function  CaculateToken1Slippage(uint256 _token1Sold)public view returns(uint256){
  //  uint256 token1Reserve;
  //   uint256 token2Reserve;
  //   (token1Reserve,token2Reserve) = getReserve();
  //   return  _token1Sold/(token1Reserve+_token1Sold);
  // }

  // function  CaculateToken2Slippage(uint256 _token2Sold)public view returns(uint256){
  //  uint256 token1Reserve;
  //   uint256 token2Reserve;
  //   (token1Reserve,token2Reserve) = getReserve();
  //   return  _token2Sold/(token2Reserve+_token2Sold);
  // }
  function min(uint256 a ,uint256 b)public pure returns(uint256){
    return a>b?1:0;
  }
}