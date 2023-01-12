// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./YHswapERC20.sol";
import "./YHswapFactory.sol";
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

   
    function sqrt(uint y) internal pure returns (uint z) {
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
}

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract YHswap is YHswapERC20{
    address factory;
    address public token0;
    address public token1;

    uint256 private balance0; //token0的余额
    uint256 private balance1;  //token1的余额
   

    constructor(address _token0, address _token1) public {
        factory=msg.sender;
        require(_token0!=address(0)&&_token1!=address(0)&&_token0!=_token1);
        token0 = _token0;
        token1 = _token1;
    }


   // 增加流动性
    function addLiquidity(uint256 minliquidity,uint256 maxtokens,address token,uint256 tokenAmount)public returns(uint256){
          require( maxtokens > 0,"addLiquidity wrong");
          require(token==token0||token==token1);
         
          if(totalLiquidity>0){
          require(minliquidity>0,"liquidity is too small");
            if(token==token0){
            (uint256 tokenAmountInput,uint256 mintedliquidity)=Liquidityjisuan0(tokenAmount);
             require(tokenAmountInput<=maxtokens && mintedliquidity>=minliquidity);
             transfer2(tokenAmount,tokenAmountInput,mintedliquidity);
             return mintedliquidity;
            }else{
           (uint256 tokenAmountInput,uint256 mintedliquidity)=Liquidityjisuan1(tokenAmount);
             require(tokenAmountInput<=maxtokens && mintedliquidity>=minliquidity);
             transfer2(tokenAmountInput,tokenAmount,mintedliquidity);
             return mintedliquidity;
            }

          }else{
              
            uint256 tokenAmountInput=maxtokens;
            uint256 mintedliquidity=Math.sqrt(tokenAmountInput*tokenAmount);  
             if(token==token0){
              transfer2(tokenAmount,tokenAmountInput,mintedliquidity);    
              }else{
              transfer2(tokenAmountInput,tokenAmount,mintedliquidity); 
              }
          }
    } 
    //移出流动性
      function removeLiquidity(uint256 amount,uint256 minToken0Amount,uint256 minToken1Amount)public returns(uint256,uint256){
          require(amount<=balances[msg.sender]);
          require(totalLiquidity>0);
          uint256 token0Amount=amount*balance0/totalLiquidity;
          uint256 token1Amount=amount*balance1/totalLiquidity;
          require(token0Amount>=minToken0Amount && token1Amount>=minToken1Amount);
          balances[msg.sender]-=amount;
          totalLiquidity-=amount;
          balance0-=token0Amount;
          balance1-=token1Amount;
          require(IERC20(token0).transfer(msg.sender,token0Amount));
          require(IERC20(token1).transfer(msg.sender,token1Amount));
          return (token0Amount,token1Amount);
      }
    
    //交易功能、滑点
    function InputSwap(address soldToken,uint256 soldAmount,uint256 minAmount)public returns(uint256){
        require(soldToken==token0||soldToken==token1);
        if(soldToken==token0){
          uint256 outAmount= inputGetOutput(soldAmount,balance0,balance1);
          require(outAmount>=minAmount);
          require(IERC20(token0).transferFrom(msg.sender,address(this),soldAmount));
          require(IERC20(token1).transfer(msg.sender,outAmount));
          balance0+=soldAmount;
          balance1-=outAmount;
          return outAmount;
        }else{
           uint256 outAmount= inputGetOutput(soldAmount,balance1,balance0);
          require(outAmount>=minAmount);
          require(IERC20(token1).transferFrom(msg.sender,address(this),soldAmount));
          require(IERC20(token0).transfer(msg.sender,outAmount));
          balance1+=soldAmount;
          balance0-=outAmount;
          return outAmount;
        }

      }
     function OutputSwap(address outToken,uint256 outAmount,uint256 maxInput)public returns(uint256){
        require(outToken==token0||outToken==token1);
        if(outToken==token0){
           uint256 InputAmount=outputGetInput(outAmount,balance1,balance0);
           require(maxInput>=InputAmount);
           require(IERC20(token1).transferFrom(msg.sender,address(this),InputAmount));
           require(IERC20(token0).transfer(msg.sender,outAmount));
           balance0-=outAmount;
          balance1+=InputAmount;
          return InputAmount;
        }else{
           uint256 InputAmount=outputGetInput(outAmount,balance0,balance1);
           require(maxInput>=InputAmount);
           require(IERC20(token0).transferFrom(msg.sender,address(this),InputAmount));
           require(IERC20(token1).transfer(msg.sender,outAmount));
           balance1-=outAmount;
          balance0+=InputAmount;
          return InputAmount;
        }
     }

   



    function Liquidityjisuan0(uint256 token0Amount)private returns(uint256,uint256){
           uint256 tokenAmountInput;
           uint256 mintedliquidity;
             tokenAmountInput = token0Amount * balance1 / balance0 + 1;
             mintedliquidity = token0Amount * totalLiquidity / balance0;
             return (tokenAmountInput,mintedliquidity);
           
}
   function Liquidityjisuan1(uint256 token1Amount)private returns(uint256,uint256){
           uint256 tokenAmountInput;
           uint256 mintedliquidity;
            tokenAmountInput = token1Amount * balance0 / balance1 + 1;
            mintedliquidity = token1Amount * totalLiquidity / balance1;
             return (tokenAmountInput,mintedliquidity);
           
}
    function transfer2(uint256 amount0,uint256 amount1,uint256 mintedliquidity)private{
       require(IERC20(token0).transferFrom(msg.sender,address(this),amount0),"token0 trasfer failed");
       require(IERC20(token1).transferFrom(msg.sender,address(this),amount1),"token1 trasfer failed");
       balances[msg.sender]+=mintedliquidity;
             totalLiquidity+=mintedliquidity;
             balance0+=amount0;
             balance1+=amount1;
       
}
    //手续费功能，千分之三手续费
    function inputGetOutput(uint256 inputamount,uint256 inputBalance,uint256 outputBalance)public returns(uint256){
      require(balance0 >0 && balance1 >0);
      uint256 inputamountfee = inputamount * 997;
      uint256 numerator = inputamountfee * outputBalance;
      uint256 denominator= (inputBalance * 1000) + inputamountfee;
    return numerator / denominator;
    }
    
    function outputGetInput(uint256 outputamount,uint256 inputBalance,uint256 outputBalance)public returns(uint256){
      require(balance0 >0 && balance1 >0);
      uint256 numerator = inputBalance * outputamount * 1000;
      uint256 denominator = (outputBalance - outputamount) * 997;
    return numerator / denominator + 1;
    }

}