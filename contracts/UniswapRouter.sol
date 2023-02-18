// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./UniswapPair.sol";
import "./UniswapFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UniswapRouter {
    UniswapFactory public factory;

    constructor(address _factory) {
        factory = UniswapFactory(_factory);
    }

    function createPair(address tokenA, address tokenB, uint256 tokenAAmount, uint256 tokenBAmount) public {
        UniswapPair pair = UniswapPair(factory.createPair(tokenA, tokenB));

        address account = msg.sender;
        ERC20(tokenA).transferFrom(account, address(pair), tokenAAmount);
        ERC20(tokenB).transferFrom(account, address(pair), tokenBAmount);
        factory.initializePair(address(pair), account);
    }
}
