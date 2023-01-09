// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./FT.sol";
contract TokenA is FT{
    constructor() FT("TokenA", "A") {
        _mint(msg.sender, 1000*10000*10**18);
    }
}