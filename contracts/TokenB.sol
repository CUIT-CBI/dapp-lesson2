// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./FT.sol";
contract TokenB is FT{
    constructor() FT("TokenB", "B") {
        _mint(msg.sender, 1000*10000*10**18);
    }
}