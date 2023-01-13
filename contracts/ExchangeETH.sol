// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";  
import "./FT.sol";
contract ExchangeETH is FT{
    IERC20 public token;

    constructor(address _tokenAddress) FT("Liquidity","L") {
        token = IERC20(_tokenAddress);
    }

    function addLiquidity(uint _tokenAmount) external payable{
        uint256 ethReserve = address(this).balance - msg.value;
        if (ethReserve == 0) {
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
        } else {
            uint256 tokenReserve = getTokenReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(_tokenAmount >= tokenAmount, "insufficient token amount");
            token.transferFrom(msg.sender, address(this), tokenAmount);
            uint256 liquidity = (msg.value * totalSupply()) / ethReserve;
            _mint(msg.sender, liquidity);
        }
    }

    function removeLiquidity(uint _amount) external {
        require(_amount > 0, "invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getTokenReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        token.transfer(msg.sender, tokenAmount);
    }

    function getTokenReserve() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function getEthReserve() public view returns(uint) {
        return address(this).balance;
    }

    function getAmount(uint _inputAmount,uint _inputReserve,uint _outputReserve) internal pure returns(uint) {
        uint outputAmount = (_outputReserve*_inputAmount)/(_inputReserve+_inputAmount);
        return outputAmount;
    }

    function getTokenAmount(uint _ethSold) view public returns(uint) {
        uint tokenOutAmount = getAmount(_ethSold, getEthReserve(),getTokenReserve());
        return tokenOutAmount;
    }

    function getEthAmount(uint tokenAmount) view public returns(uint) {
        uint ethOutAmount = getAmount(tokenAmount, getTokenReserve(), getEthReserve());
        return ethOutAmount;
    }

    function ethToToken(uint _minTokens) external payable {
        uint ethReserve = getEthReserve()-msg.value;
        require(msg.value>0,"too less");
        uint tokenOutAmount = getAmount(msg.value,ethReserve,getTokenReserve());
        tokenOutAmount = (tokenOutAmount*997)/1000;
        require(tokenOutAmount>=_minTokens,'less than mintokens');
        token.transfer(msg.sender,tokenOutAmount);
    }

    function tokenToEth(uint _minEth,uint _tokenSold) external {
        require(_tokenSold>0,"too less");
        uint ethOutAmount = getEthAmount(_tokenSold);
        ethOutAmount=(ethOutAmount*997)/1000;
        require(ethOutAmount>=_minEth,'less than _minEth');
        token.transferFrom(msg.sender,address(this),_tokenSold);
        payable(msg.sender).transfer(ethOutAmount);
    }

}