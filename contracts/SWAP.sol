//SPDX-License-Identifier:UNLISENCED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./FT.sol";
import "./Math.sol";

/* 
### 1. 增加/移出流动性                      30分
### 2. 交易功能                            30分
### 3. 实现手续费功能，千分之三手续费        10分
### 4. 实现滑点功能                         15分
*/

contract swap {

    address public token1;
    address public token2;
    uint256 public token1Supply;
    uint256 public token2Supply;
    uint public  liquidity; 


    constructor(address _token1, address _token2) {        
        token1 = _token1;
        token2 = _token2;
    }


    function changeAmount() public {
        token1Supply = ERC20(token1).balanceOf(address(this));
        token2Supply = ERC20(token2).balanceOf(address(this));
    }

    function init(uint256 token1Amount, uint256 token2Amount) public payable  {
        require(sign == 0);
        sign = 1;
        token1Supply = token1Amount;
        token2Supply = token2Amount;
        ERC20(token1).transferFrom(msg.sender, address(this), token1Amount);
        ERC20(token2).transferFrom(msg.sender, address(this), token2Amount);
        uint initLiquidity = sqrt(_amount0 * _amount1);
        _mint(msg.sender, initLiquidity);
    }

    // 增加流动性
    // _token: 要增加流动性的代币地址
    // _amount: 要增加流动性的数量
    // liquidity: 增加后的流动性总量
    function addLiquidity(address _token, uint256 _amount) external returns (uint256) {
        // 检查输入的代币地址是否合法
        require(_token == token1 || _token == token2,"Invalid address!");
        uint amount1;
        uint amount2;

        // 计算对应增加另一种代币的数量
        if(_token == token1){
            //amount2 = token2Supply * amount1 / token1Supply; 
            //SafeMath
            amount2 = token2Supply.mul(_amount).div(token1Supply);
        } else {
            amount1 = token1Supply.mul(_amount).div(token2Supply);
        }
        // 从用户账户转移代币到合约账户
        ERC20(token0).transferFrom(msg.sender, address(this), amount1);
        ERC20(token1).transferFrom(msg.sender, address(this), amount2);
        // 计算流动性总量
        liquidity = min(totalSupply() * amount1 / token1Suppl, totalSupply() * amount2 / token2Supply);
        // 增加流动性
        _mint(msg.sender, liquidity);
        // 更新代币存量
        changeAmount();
        return liquidity;
    }

    function removeLiquidity(uint256 _liquidity) 
        external 
        payable 

        returns (uint256, uint256)
    {
        require(_liquidity > 0 );
        uint256 balance1 = ERC20(token1).balanceOf(address(this));
        uint256 balance2 = ERC20(token2).balanceOf(address(this));

        amount1 = _liquidity.mul(balance1).div(totalSupply());
        amount2 = _liquidity.mul(balance2).div(totalSupply());

        _burn(msg.sender, _liquidity);

        ERC20(token1).transfer(msg.sender, amount1);
        ERC20(token2).transfer(msg.sender, amount2);

        changeAmount();

        return (amount1, amount2);
    }

    function swapToken(address _token, uint256 SwapTokenAmount) external payable returns(uint256 getTokenAmount){
         if(_token == token1){
            ERC20(token1).transferFrom(msg.sender, address(this), SwapToken1Amount);
            getToken2Amount = (token2Supply - (token1Supply * token2Supply) / (token1Supply + SwapToken1Amount))  * 997 / 1000;   
            ERC20(token2).transfer(msg.sender, getToken2Amount);
            changeAmount();
         }
         if(_token == token2){
            ERC20(token2).transferFrom(msg.sender, address(this), SwapToken2Amount);
            getToken1Amount = (token1Supply - (token2Supply * token1Supply) / (token2Supply + SwapToken2Amount))  * 997 / 1000;   
            ERC20(token1).transfer(msg.sender, getToken1Amount);
            changeAmount();
         }
    }


    function SwapUnderslip(address _token, uint256 _inputAmount, uint256 _minTokens) external returns (uint256){
        require(_token == token1 || _token == token2);
        uint256 expectGetAmount;
        uint256 actualGetAmount;
        uint256 slipPoint = 5;
        if(_token == token1){
            expectGetAmount = token2Supply * _inputAmount / token1Supply;
            actualGetAmount = swapToken(_token, _inputAmount, _minTokens);
        }
        if(_token == token2){
            expectGetAmount =  token1Supply * _inputAmount /token2Supply;
            actualGetAmount = swapToken(_token, _inputAmount, _minTokens);
        }
        uint256 slip = (expectGetAmount - actualGetAmount) * 1000 / expectGetAmount;
        require(slip <= slipPoint,"Cannot exceed the set sliding point");
        changeAmount();
    }
}