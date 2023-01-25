// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FT is ERC20, Pausable, Ownable {
    address public myTokenAddress;
    constructor(string memory name, string memory symbol,address _myToken) ERC20(name, symbol) {
        require(_myToken != address(0));
        myTokenAddress = _myToken;
    }
    
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    function getReserve() public view returns (uint256) {
        return ERC20(myTokenAddress).balanceOf(address(this));
    }

    //Adding into liquidity Pool
    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 liquidity;
        uint256 ethBal = address(this).balance;
        uint256 reserve = getReserve();
        ERC20 myToken = ERC20(myTokenAddress);
        if (reserve == 0) {
            myToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethBal;
            _mint(msg.sender, liquidity);
        
        } 
        else 
        {
            uint256 ethReserve = ethBal - msg.value;
            uint256 myTokenCheck = (msg.value * reserve) / ethReserve;
            require(
                _amount >= myTokenCheck,
                "Entered Value is less than minimum token required"
            );
            myToken.transferFrom(msg.sender, address(this), myTokenCheck);
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }
    function removeLiquidity(uint256 _amount) public returns (uint256, uint256){
        require(_amount > 0, "Amount must be greater than Zero");
        uint256 ethReserve = address(this).balance;
        uint256 _totalSupply = totalSupply();
        uint256 amountEth = (_amount * ethReserve) / _totalSupply;
        _burn(msg.sender, _amount);
        uint256 _myToken = (_amount * getReserve()) / _totalSupply;
        payable(msg.sender).transfer(amountEth);
        ERC20.transfer(msg.sender, _myToken);
        return (amountEth, _myToken);
    }
    function getAmountTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Values less than zero");
        uint256 inputAmountFee = inputAmount * 99;
        uint256 numerator = inputAmountFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountFee;
        return numerator / denominator;
    }

    //From Eth to ERC20 token
    function ethTomyToken(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        require(tokensBought >= _minTokens, "insufficient output amount");
        ERC20(myTokenAddress).transfer(msg.sender, tokensBought);
    }

    //from ERC20 to eth token
    function mytokenToEth(uint256 _tokenSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmountTokens(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficient output amount");
        ERC20(myTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenSold
        );
        payable(msg.sender).transfer(ethBought);
    }
}
