// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
struct addLS{
  uint256 tokenHigh;
  uint256 tokenLow;//以token2为例即token2位x轴
  uint256 token1Amount;//用户提供的token1amount
  uint256 token2Amount; //用户提供的token2amount
}//流动性增加结构体
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 import "@openzeppelin/contracts/utils/math/Math.sol";

contract  uniswap is ERC20{
  address  public token1Address;
  address  public token2Address;

    constructor(address _token1A,address _token2A)ERC20("L" , "Lp"){
      require(_token1A != address(0),"invalid address");
      require(_token2A != address(0),"invalid address");
      token1Address=_token1A; 
      token2Address=_token2A; 
    }
    //流动性的增加与移除 
    //增加流动性 
    //流动性提供商会首先会进行抉择一个代币价格区间范围进行相关投入进去
  function addL(addLS memory als)public  returns(uint256){
    //当前池子中不具有流动性
    uint256 token1Reserve;
    uint256 token2Reserve;
    (token1Reserve, token2Reserve) = getReserve();//获取当前池子中的token数量
    uint256 liquidity;
    if (token1Reserve==0&&token2Reserve==0) {
      //将提供流动性的用户的钱转入合约中
      IERC20 token1= IERC20(token1Address);
      IERC20 token2= IERC20(token2Address);
      token1.transferFrom(msg.sender, address(this), als.token1Amount);
      token2.transferFrom(msg.sender, address(this), als.token2Amount);
       //奖励
      _mint(msg.sender, 10**5);
      return uint256(10**5);
    }else{
    uint256 k = token1Reserve*token2Reserve;
    uint256 Pc = token1Reserve/token2Reserve;
    uint256 pa=k/(als.tokenHigh*als.tokenHigh);
    uint256 pb = k/(als.tokenLow*als.tokenLow);
      if (Pc<pa){
          liquidity = (als.tokenHigh-als.tokenLow)/(1/Math.sqrt(pa)-1/Math.sqrt(pb));
          IERC20(token2Address).transferFrom(msg.sender,address(this),als.token2Amount);
      }else if(Pc>pb){
        liquidity = (k/als.tokenLow-k/als.tokenHigh)/(Math.sqrt(pb)-Math.sqrt(pa));
        IERC20(token1Address).transferFrom(msg.sender,address(this),als.token2Amount);
      }else{
        liquidity = (token2Reserve-als.tokenLow)/(1/Math.sqrt(Pc)-1/Math.sqrt(pb));
        IERC20(token2Address).transferFrom(msg.sender,address(this),als.token2Amount);
        uint256 tokena = liquidity*(Pc-pa);
        require(tokena<=als.token1Amount);
        IERC20(token2Address).transferFrom(msg.sender,address(this),tokena);
      }
      _mint(msg.sender,liquidity);
      return liquidity;
   }
  }
//移除流动性 
function removeL(uint256 liquidity)public returns(uint256,uint256){
    require(liquidity>0,"invalid");
    assert(transfer(address(this), liquidity));
    uint256 token1Reserve;
    uint256 token2Reserve;
    (token1Reserve, token2Reserve) = getReserve();//获取当前池子中的token数量
    uint256 token1Amount =liquidity *  token1Reserve/ totalSupply();
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
    uint256  inputAmountWithoutFee = inputAmount-(inputAmount*3)/1000;
    uint256  numerator = inputAmountWithoutFee*outputReserve;
    uint256  denominator = inputAmountWithoutFee + inputReserve;
    return  numerator/denominator;
  }
  // 交易功能
  // 获取当前token1能换多少token2
  function  getT1Amount(uint256 _t1Sold)public view returns(uint256){
    require(_t1Sold > 0,"invalid");
    uint256 token1Reserve;
    uint256 token2Reserve;
     (token1Reserve, token2Reserve) = getReserve();
    return getAmount(_t1Sold, token1Reserve, token2Reserve);
  }
  //获取当前token2能换多少token1
  function getT2Amount(uint256 _t2Sold)public view returns(uint256){
    require(_t2Sold > 0,"invalid");
     uint256 token1Reserve;
    uint256 token2Reserve;
     (token1Reserve, token2Reserve) = getReserve();
    return getAmount(_t2Sold, token2Reserve, token1Reserve);
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
    //uint256 _minEth = token2Bought-token2Bought*CaculateToken2Slippage(token2Bought);//滑点计算公式
    require(token2Bought>=_mintokens,"insuffcient output");
    IERC20(token1Address).transferFrom(msg.sender, address(this), _token1Sold);
    this.transfer(msg.sender, token2Bought);
  }
  //token1滑点百分比计算
//  function  CaculateToken1Slippage(uint256 _t1Sold)public view returns(uint256){
//   uint256 token1Reserve;
//    uint256 token2Reserve;
//    (token1Reserve,token2Reserve) = getReserve();
//    return  _t1Sold/(token1Reserve+_t1Sold);
//  }
//token2滑点百分比计算
//  function  CaculateToken2Slippage(uint256 _t2Sold)public view returns(uint256){
//    uint256 token1Reserve;
//    uint256 token2Reserve;
//    (token1Reserve,token2Reserve) = getReserve();
//    return  _t2Sold/(token2Reserve+_t2Sold);
//  }
}
