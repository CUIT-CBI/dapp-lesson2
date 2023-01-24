pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PmlERC20 is ERC20 {
    constructor() ERC20("PmlERC20", "Pml") {}
}
