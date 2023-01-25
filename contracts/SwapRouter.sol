// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SwapPair.sol";
import "./SwapFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SwapRouter {
    SwapFactory public factory;

    constructor(address _factory) {
        factory = SwapFactory(_factory);
    }

    function crPair(address token0, address token1, uint256 token0Amount, uint256 token1Amount) public returns (address) {
        SwapPair pair = SSQSwapPair(factory.crPair(token0, token1));

        address account = msg.sender;
        ERC20(token0).transferFrom(account, address(pair), token0Amount);
        ERC20(token1).transferFrom(account, address(pair), token1Amount);
        factory.initPair(address(pair), account);

        return address(pair);
    }
}