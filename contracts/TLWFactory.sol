pragma solidity =0.5.16;

import './interfaces/ITLWFactory.sol';
import './TLWPair.sol';

contract TLWFactory is ITLWFactory {
    address feeTo;
    address feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != address(0) || tokenB != address(0), '有零地址，请检查token地址是否有效');
        require(tokenA != tokenB, '相同的地址，请检查俩个token是否不同');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), '此交易对已经存在！');
        bytes memory bytecode = type(TLWPair).creationCode;
        bytes32 sugar = keccak256(abi.encodePacked(token0, token1));

        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), sugar)
        }
        ITLWPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
//手续费去向设置
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, '权限不足，你不是管理员！');
        feeTo = _feeTo;
    }
//手续费管理员设置
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, '权限不足，你不是管理员！');
        feeToSetter = _feeToSetter;
    }
}
