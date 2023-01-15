// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable{
    constructor() ERC20("LP Reward", "LPR") {
        _mint(msg.sender, 1000e18);
    }

    function mint(address account ,uint amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint amount) external onlyOwner {
        _burn(account, amount);
    }
}