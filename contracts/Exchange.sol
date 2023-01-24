//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IFactory.sol";
import "./IExchange.sol";

contract Exchange is ERC20{
    address public tokenAddress;
    address public factoryAddress;

    constructor(address _tokenAddress, address _factoryAddress) ERC20("swap-v1", "SWAP_V1") {
        require(_tokenAddress != address(0), "invalid address");
        tokenAddress = _tokenAddress;
        factoryAddress = _factoryAddress;
    }

    /**
     * @dev add liquidity to the decentralized exchange
     */
    function addLiquidity(uint256 _amount) public payable returns(uint256) {
        if(getReserve() == 0) {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _amount);

            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;

        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(tokenAmount <= _amount, "invalid amount");
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);

            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    /**
     * @dev remove liquidity from the decentralized exchange
     */
    function removeLiquidity(uint256 _amount) public returns(uint256, uint256) {
        require(_amount > 0, "invalid");
        uint256 ethAmount = _amount * address(this).balance / totalSupply();
        uint256 tokenAmount = getReserve() * _amount / totalSupply();
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }
    

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) private pure returns (uint256) {
        require(inputAmount > 0 && outputReserve > 0, "invalid reserves");

        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = inputAmountWithFee + (inputReserve * 1000);
        return numerator / denominator;
    }

    function getTokenAmount(uint256 _ethSold) public view returns(uint256) {
        require(_ethSold > 0, "invalid");
        uint256 tokenReserve = getReserve();
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }
    
    /**
     * @dev get eth amount
     */
    function getEthAmount(uint256 _tokenSold) public view returns(uint256) {
        require(_tokenSold > 0, "invalid");
        uint256 tokenReserve = getReserve();
        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);

        
    }
    /**
     * @dev swap eth to token
     */
    function ethToToken(uint256 _minTokens, address recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokenBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        require(tokenBought >= _minTokens, "insufficient output");
        IERC20(tokenAddress).transfer(recipient, tokenBought);
    }

    function ethToTokenTransfer(uint256 _minTokens, address recipient) public payable {
        ethToToken(_minTokens, recipient);
    }
    
    /**
     * @dev swap token to eth
     */
    function tokenToEthSwap(uint256 _tokenSold, uint256 _mintEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve,address(this).balance);
        require(ethBought >= _mintEth, "insufficient output");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);
    }

    /**
     * @dev swap any ERC20 token to another ERC20 token, at some dex the token can have more complex behavior
     */
    function tokenToToken(uint256 _tokenSold, uint256 _minTokenBought, address _tokenAddress) public {
        address exchangeAddress = IFactory(factoryAddress).getExchange(_tokenAddress);
        require(exchangeAddress != address(this) && exchangeAddress != address(0), "invalid exchange address");    

        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);

        IExchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(_minTokenBought, msg.sender);
    
    }

}
