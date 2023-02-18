pragma solidity >=0.5.0;

interface IGzxFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function PairBytecode() external view returns (bytes memory);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
