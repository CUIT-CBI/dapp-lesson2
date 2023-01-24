//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    constructor() ERC20("ZhouZhe", "ZZ") {

    }

   function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}