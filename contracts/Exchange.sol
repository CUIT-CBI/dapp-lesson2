// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FT.sol";

contract Exchange is FT{

    IERC20 public token1;
    IERC20 public token2;
    uint public reserve1;
    uint public reserve2;

    constructor(address _token1,address _token2) FT("Uniswap","hyr"){
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }  

    // x1/y1 = x2/y2 
    function addLiquidity(uint _Amount1, uint _Amount2) external{
        uint256 liquidity;
        require (_Amount1 != 0 && _Amount2 != 0);
        // immediately calculate
        if(reserve1 == 0) {
            token1.transferFrom(msg.sender, address(this), _Amount1);
            token2.transferFrom(msg.sender, address(this), _Amount2);
            liquidity = _Amount1;
            reserve1 += _Amount1;
            reserve2 += _Amount2;
            _mint(msg.sender, liquidity);
        } else {
            // making variable calculate a priority
            // x1 = (x2 * y1) / y2
            uint256 _amount1 = (_Amount2 * reserve1) / reserve2;
            require (_Amount1 >= _amount1);
            token1.transferFrom(msg.sender, address(this), _amount1);
            token2.transferFrom(msg.sender, address(this), _Amount2);
            liquidity = (totalSupply() * _amount1) / reserve1;
            reserve1 += _amount1;
            reserve2 += _Amount2;
            _mint(msg.sender, liquidity);
        }
    }

    function rmLiquidity(uint256 _Amount1) public {
        require(_Amount1 > 0 && _Amount1 <= (balanceOf(msg.sender) * reserve1) / totalSupply());

        uint256 _amount2 = (_Amount1 * reserve2) / reserve1;

        _burn(msg.sender, _Amount1);

        token1.transfer(msg.sender, _Amount1);
        token2.transfer(msg.sender, _amount2);

        reserve1 -= _Amount1;
        reserve2 -= _amount2;
        
    }

    // xy === N
    function getAmount(uint256 _inputAmount, uint256 _inputReserve, uint256 _outputReserve) internal pure returns (uint256) {
        require(_inputReserve > 0 && _outputReserve > 0);
        // magnify:float calculations are invalid, all elements must enlarge thousand times
        uint256 afterDisposalInput = _inputAmount * 997;
        // Reserve of the pond
        uint256 pondNewReserve = (_inputReserve * 1000) + afterDisposalInput;
        uint256 proportion = _outputReserve * afterDisposalInput;
        uint256 output = proportion / pondNewReserve;
        return output;
    }

    // exchange
    function token1To2(uint256 slippage, uint256 _amount) public {
        uint256 outputAmount = getAmount(_amount, reserve1, reserve2);
        require(outputAmount >= slippage);
        token1.transferFrom(msg.sender, address(this), _amount);
        token2.transfer(msg.sender,outputAmount);
        reserve1 += _amount;
        reserve2 -= outputAmount;
    }
    
    function token2to1(uint256 slippage, uint256 _amount) public {
        uint256 outputAmount = getAmount(_amount, reserve2, reserve1);
        require(outputAmount >= slippage);
        token1.transferFrom(msg.sender, address(this), _amount);
        token2.transfer(msg.sender,outputAmount);
        reserve1 -= outputAmount;
        reserve2 += _amount;
    }    
}