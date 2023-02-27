// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract FT is ERC20 {
contract FT is ERC20, Pausable, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) external onlyOwner {
@@ -13,5 +15,16 @@ contract FT is ERC20 {
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
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
}
