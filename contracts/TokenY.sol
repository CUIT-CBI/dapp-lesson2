// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract tokenY is ERC20 {
    constructor() ERC20("TokenY", "Y") {
        _mint(msg.sender, 1000000e18);
    }
}