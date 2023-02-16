// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../SwapERC20.sol';

contract ERC20 is SwapERC20 {
    constructor(uint _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}
