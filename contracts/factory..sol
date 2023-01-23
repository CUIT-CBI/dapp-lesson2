// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Factory.sol';
import './SwapPair.sol';

contract factory{

    //构造器，在factory合约初始化时传入手续费管理员地址
    constructor(
        address _feeToSetter//手续费管理员地址
    ) public {
        feeToSetter = _feeToSetter;
    }

    address public feeTo;//接受千分之三手续费的地址/手续费接收地址
    address public feeToSetter;//手续费管理员地址
    
    // address public tokenA_pool;//存放tokenA的交易池子
    // address public tokenB_pool;//存放tokenB的交易池子
    //存放转换的两种代币存放的地址/流动性池
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;//资金池数组
    
    event catePair_event(address indexed token0, address indexed token1, address pair, uint);
    
    

    //查询资金池的总数
    function allPairsLength() external view returns(uint){
        return allPairs.length;
    }

    //传入tokenA和tokenB的地址返回资金池的地址
    function createPair (
        address tokenA, //tokenA的地址
        address tokenB//tokenB的地址
    ) external returns (
        address pair//资金池的地址
    ) {
        //两个地址不能够相同
        require(tokenA != tokenB,'identical_addresses');
        //统一调整代币的前后顺序，将小的放在前面，防止出现重复的代币对，比如(a,b)和(b,a)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        //确保地址不为空
        require(token0 != address(0),'zero_address');
        //判断代币对是否已经存在
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS');
        //获取UniswaV2Pair合约的字节码
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        //使用参数token0,token1计算salt
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        //使用create2部署pair合约
        assembly {
            //create2(创建合约发送的 ETH 数量、bytecode 起始位置、bytecode 长度、生成合约地址的随机盐值)
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //pair合约初始化
        IUniswapV2Pair(pair).initialize(token0, token1);
        //记录token0,token1创建的资金池地址是pair
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        //将pair pull到资金池数组中
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
    
    //设置手续费接受地址
    function setFeeTo(address _feeTo) external {
        //检查调用者是否是手续费管理员
        require(msg.sender == feeToSetter, 'forbidden');
        feeTo = _feeTo;
    }

    //设置用户地址
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'forbidden');
        feeToSetter = _feeToSetter;
    }

}