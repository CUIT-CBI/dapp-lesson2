// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface V2Pair {
    function initPair(address, address) external;

    function getReserves() external returns ( uint112, uint112, uint32);

    function transferFrom( address, address,uint256) external returns (bool);

    function mint(address) external returns ( uint256);

    function burn(address) external returns ( uint256, uint256);

    function swap(uint256,uint256,address) external;

    function getToken0() external view returns (address);

    function getToken1() external view returns (address);

    function getTokenReserve(address token)external view returns (uint112);
}