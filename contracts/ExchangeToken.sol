// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract ExchangeToken is FT{
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint public reserveA;
    uint public reserveB;


    constructor(address _tokenA,address _tokenB) FT("Liquidity","L"){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    function addLiquidity(uint amountA,uint amountB) external{
        require(amountA!=0&&amountB!=0,'invild add');
        if (reserveA == 0) {
            tokenA.transferFrom(msg.sender, address(this), amountA);
            tokenB.transferFrom(msg.sender, address(this), amountB);
            uint256 liquidity = amountA;
            _mint(msg.sender, liquidity);
            reserveA += amountA;
            reserveB += amountB;
        } else {
            uint256 tokenAAmount = (amountB * reserveA) / reserveB;
            require(amountA >= tokenAAmount-1, "insufficient token amount");
            tokenA.transferFrom(msg.sender, address(this), tokenAAmount);
            tokenB.transferFrom(msg.sender, address(this), amountB);
            uint256 liquidity = (amountA * totalSupply()) / reserveA;
            _mint(msg.sender, liquidity);
            reserveA += tokenAAmount;
            reserveB += amountB;
        }
    }

    function removeLiquidity(uint _amountA) external {
        require(_amountA > 0 && _amountA<=(balanceOf(msg.sender)*reserveA)/totalSupply(), "invalid amount");
        uint amountB = (_amountA*reserveB)/reserveA;
        _burn(msg.sender, _amountA);
        reserveA-=_amountA;
        reserveB-=amountB;
        tokenA.transfer(msg.sender, _amountA);
        tokenB.transfer(msg.sender, amountB);
    }


    function getAmount(uint _inputAmount,uint _inputReserve,uint _outputReserve) internal pure returns(uint) {
        uint outputAmount = (_outputReserve*_inputAmount)/(_inputReserve+_inputAmount);
        return outputAmount;
    }

    function getTokenAAmount(uint amountB) view public returns(uint) {
        uint tokenOutAmount = getAmount(amountB, reserveB,reserveA);
        return tokenOutAmount;
    }

    function getTokenBAmount(uint amountA) view public returns(uint) {
        uint tokenOutAmount = getAmount(amountA, reserveA,reserveB);
        return tokenOutAmount;
    }

    function tokenAToB(uint _minTokens,uint _amount) external {
        uint tokenOutAmount = getTokenBAmount(_amount);
        tokenOutAmount = tokenOutAmount *997/1000;
        require(tokenOutAmount>=_minTokens,'less than mintokens');
        reserveB-=tokenOutAmount;
        tokenA.transferFrom(msg.sender, address(this), _amount);
        tokenB.transfer(msg.sender,tokenOutAmount);
        reserveA+=_amount;
    }

    function tokenBToA(uint _minTokens,uint _amount) external {
        uint tokenOutAmount = getTokenAAmount(_amount);
        tokenOutAmount = tokenOutAmount *997/1000;
        require(tokenOutAmount>=_minTokens,'less than mintokens');
        reserveA-=tokenOutAmount;
        tokenB.transferFrom(msg.sender, address(this), _amount);
        tokenA.transfer(msg.sender,tokenOutAmount);
        reserveB+=_amount;
    }
}