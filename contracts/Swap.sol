// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.6;

import "./FT.sol";
import "./math.sol";

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

     function addLiquidity(address _token, uint256 _amount) 
        external
        returns (uint256) 
    {
        require(_token == token1 || _token == token2,"Invalid address!");
        uint amount1;
        uint amount2;
       
        if(_token == token1){
            amount1 = _amount;
            
            amount2 = token2Supply * amount1 / token1Supply;            
        } else {
            amount2 = _amount;
            
            amount1 = token1Supply * amount2 / token2Supply;
        }

        ERC20(token0).transferFrom(msg.sender, address(this), amount1);
        ERC20(token1).transferFrom(msg.sender, address(this), amount2);

        
        liquidity = min(totalSupply() * amount1 / token1Suppl, totalSupply() * amount2 / token2Supply);
        
        _mint(msg.sender, liquidity);

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
        
        amount1 = _liquidity * balance1 / totalSupply();       
        amount2 = _liquidity * balance2 / totalSupply();
        
        _burn(msg.sender, _liquidity);

        ERC20(token1).transfer(msg.sender, amount1);
        ERC20(token2).transfer(msg.sender, amount2);

        changeAmount();

        return (amount1, amount2);
    }
 
    //使用Token1交换Token2
    function swapToken1(uint256 SwapToken1Amount)
        external
        payable
        
        returns (uint256 getToken2Amount)
    {
        ERC20(token1).transferFrom(msg.sender, address(this), SwapToken1Amount);
        getToken2Amount = (token2Supply - (token1Supply * token2Supply) / (token1Supply + SwapToken1Amount))  * 997 / 1000;   
        ERC20(token2).transfer(msg.sender, getToken2Amount);
        changeAmount();
    }
        
    

    // 使用Token2交易得到Token1 
    function swapToken2(uint256 SwapToken2Amount)
        external
        payable
        
        returns (uint256 getToken1Amount)
    {
        ERC20(token2).transferFrom(msg.sender, address(this), SwapToken2Amount);
        getToken1Amount = (token1Supply - (token2Supply * token1Supply) / (token2Supply + SwapToken2Amount))  * 997 / 1000;   
        ERC20(token1).transfer(msg.sender, getToken1Amount);
        changeAmount();
    }

    
    function SwapUnderslip(address _token, uint256 _inputAmount, uint256 _minTokens) external returns (uint256){
        require(_token == token1 || _token == token2);
        uint256 expectGetAmount;
        uint256 actualGetAmount;
        uint256 slipPoint = 5;
        if(_token == token1){
            expectGetAmount = token2Supply * _inputAmount / token1Supply;
            actualGetAmount = swapToken1(_inputAmount, _minTokens);
        }
        if(_token == token1){
            expectGetAmount =  token1Supply * _inputAmount /token2Supply;
            actualGetAmount = swapToken2(_inputAmount, _minTokens);
        }
        uint256 slip = (expectGetAmount - actualGetAmount) * 1000 / expectGetAmount;
        
        require(slip <= slipPoint,"Cannot exceed the set sliding point");

        changeAmount();
    }


}

