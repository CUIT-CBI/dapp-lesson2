// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface Pair2 {
    function init(address, address) external;

    function getReserve() external returns ( uint112, uint112, uint32);

    function transferFrom( address, address,uint256) external returns (bool);

    function mint(address) external returns ( uint256);

    function burn(address) external returns ( uint256, uint256);

    function swap(uint256,uint256,address) external;

    function getTokenA() external view returns (address);

    function getTokenB() external view returns (address);

    function getTokenReserve(address token)external view returns (uint112);
}