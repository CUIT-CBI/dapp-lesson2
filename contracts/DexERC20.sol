// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DexERC20 is ERC20 {
    constructor() ERC20("Dex ERC20", "Dex LP") {}
}