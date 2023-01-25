// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FT.sol";

contract Exchange is FT{

    IERC20 public tokenone;
    IERC20 public tokentwo;
    uint public reserveone;
    uint public reservetwo;

    constructor(address _tokenone,address _tokentwo) FT("Uniswap","hyr"){
        tokenone = IERC20(_tokenone);
        tokentwo = IERC20(_tokentwo);
    }  

                 // x1/y1 = x2/y2 
    function addIsData(uint _Amount1, uint _Amount2) external{
        uint256 isData;
        require (_Amount1 != 0 && _Amount2 != 0);
        if(reserveone == 0) {
            tokenone.transferFrom(msg.sender, address(this), _Amount1);
            tokentwo.transferFrom(msg.sender, address(this), _Amount2);
            isData = _Amount1;
           reserveone += _Amount1;
            reservetwo += _Amount2;
            _mint(msg.sender, isData);
        } else {
                // x1 = (x2 * y1) / y2
            uint256 _amount1 = (_Amount2 * reserveone) /reservetwo;
            require (_Amount1 >= _amount1);
            tokenone.transferFrom(msg.sender, address(this), _amount1);
            tokentwo.transferFrom(msg.sender, address(this), _Amount2);
            isData = (totalSupply() * _amount1) / reserveone;
            reserveone += _amount1;
            reservetwo += _Amount2;
            _mint(msg.sender, isData);
        }
    }

    function rmIsData(uint256 _Amount1) public {
        require(_Amount1 > 0 && _Amount1 <= (balanceOf(msg.sender) * reserveone) / totalSupply());

        uint256 _amount2 = (_Amount1 * reservetwo) / reserveone;

        _burn(msg.sender, _Amount1);

        tokenone.transfer(msg.sender, _Amount1);
        tokentwo.transfer(msg.sender, _amount2);

        reserveone -= _Amount1;
        reservetwo -= _amount2;

    }

    function getAmount(uint256 _amountInput, uint256 _reserveInput, uint256 _reserveOutput) internal pure returns (uint256) {
        require(_reserveInput > 0 && _reserveOutput > 0);
        // magnify:float calculations are invalid, all elements must enlarge thousand times
        uint256 inputAfterDisposal = _amountInput * 997;
        // Reserve of the pond
        uint256 pondNewReserve = (_reserveInput * 1000) + inputAfterDisposal;
        uint256 proportion = _reserveOutput * inputAfterDisposal;
        uint256 output = proportion / pondNewReserve;
        return output;
    }

    // exchange
    function tokenfTos(uint256 canvas, uint256 _amount) public {
        uint256 outputAmount = getAmount(_amount, reserveone, reservetwo);
        require(outputAmount >= canvas);
        tokenone.transferFrom(msg.sender, address(this), _amount);
        tokentwo.transfer(msg.sender,outputAmount);
        reserveone += _amount;
        reservetwo -= outputAmount;
    }

    function tokenftos(uint256 canvas, uint256 _amount) public {
        uint256 outputAmount = getAmount(_amount, reservetwo, reserveone);
        require(outputAmount >= canvas);
        tokenone.transferFrom(msg.sender, address(this), _amount);
        tokentwo.transfer(msg.sender,outputAmount);
        reserveone -= outputAmount;
        reservetwo += _amount;
    }    
    //2020131174 彭梁华
}