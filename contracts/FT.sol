// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// FT is a contract for my FT token
contract FT is ERC20, Pausable, Ownable {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
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

    // 增加代币流动性，只有合约拥有者可以调用
    function addLiquidity(uint256 amount) external onlyOwner {
        _mint(address(this), amount);
    }

    // 移除代币流动性，只有合约拥有者可以调用
    function removeLiquidity(uint256 amount) external onlyOwner {
        _burn(address(this), amount);
    }

    //交易功能，实现滑点功能，手续费功能
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 price = getLatestPrice();
        require(checkSlip(amount, price), "slip too much");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    //交易功能，实现手续费功能，手续费是0.3%
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 fee = amount * 3 / 1000;
        uint256 amountAfterFee = amount - fee;
        super._transfer(sender, recipient, amountAfterFee);
        super._transfer(sender, owner(), fee);
    }

    //实现滑点功能，校验参数的价格是否在滑点范围0.5%内，比较的是参数的价格和当前价格的差值
    function checkSlip(uint256 amount, uint256 price) internal view returns (bool) {
        uint256 currentPrice = getLatestPrice();
        uint256 slip = amount * 5 / 1000;
        if (price > currentPrice) {
            if (price - currentPrice > slip) {
                return false;
            }
        } else {
            if (currentPrice - price > slip) {
                return false;
            }
        }
        return true;
    }

    //获取当前价格,使用随机数模拟，实际应该是从oracle获取，这里为了方便，直接返回一个随机数
    function getLatestPrice() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100;
    }
   
   
    
    
}
