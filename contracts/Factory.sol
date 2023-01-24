// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Pair.sol";
contract Factory{
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    // 初始化就设定好谁是设定手续费接收的人的设定者
   constructor() public {
        feeToSetter = msg.sender;
    }

    // 获取一共有多少个交易对
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    // 创建交易对函数
    // 创建交易对只是创建一个 交易对地址 ，还没有往里面添加代币数量
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        //必须是两个不一样的ERC20合约地址
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        // 让tokenA和tokenB的地址从小到大排列
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        //token地址不能是0
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        //必须是uniswap中未创建过的pair
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient

        //获取模板合约UniswapV2Pair的creationCode
        bytes memory bytecode = type(Pair).creationCode;
        // //以两个token的地址作为种子生产salt
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // //直接调用汇编创建合约
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //初始化刚刚创建的合约
        Pair(pair).initialize(token0, token1);
        // 交易对映射填充
        //记录刚刚创建的合约对应的pair
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // 设置接收手续费的人，只能设置者能设置
    // 用于设置feeTo地址，只有feeToSetter才可以设置。
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    // 设置接收手续费的人的设置者，只能上一个设置者进行设置，也就是设置权利转交
    // 用于设置feeToSetter地址，必须是现任feeToSetter才可以设置。
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function getpair(address tokenA,address tokenB) external view returns(address){
        return getPair[tokenA][tokenB];
    }

    function getFeeTo() external view returns(address){
        return feeTo;
    }
    
    function getFeeToSetter() public view returns(address){
        return feeToSetter;
    }

}