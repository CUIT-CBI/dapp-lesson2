// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './interfaces/IUniswapFactory.sol';
import './UniswapPair.sol';

// 合约结构 UniswapV2ERC20 继承 UniswapV2Pair 引用 UniswapV2Factory
contract UniswapFactory is IUniswapFactory {
    address override public feeTo; //收税地址
    address override public feeToSetter; //收税权限控制地址

    //配对映射,地址=>(地址=>地址) tokenA tokenB 配对合约
    mapping(address => mapping(address => address)) override public getPair;

    //所有配对数组
    address[] override public allPairs;
    //配对合约的Bytecode的hash
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(UniswapPair).creationCode));

    constructor() public {
        feeToSetter = msg.sender;
    }

    function allPairsLength() override external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) override external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        //将tokenA和tokenB进行大小排序,确保tokenA小于tokenB
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        //确认token0不等于0地址 token1也就不等于0地址
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        //确认配对映射中不存在token0=>token1 还没有创建配对合约
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        //给bytecode变量赋值"UniswapV2Pair"合约的创建字节码 合约源代码编译之后得到的
        bytes memory bytecode = type(UniswapPair).creationCode;
        //将token0和token1打包后创建哈希
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        //内联汇编
        //solium-disable-next-line
        assembly {
        //通过create2方法布署合约,并且加盐,返回地址到pair变量 create2只能使用内联汇编因为这是opcode
            // 返回地址的同时，也把合约部署在链上。
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //调用pair地址的合约中的"initialize"方法,传入变量token0,token1
        IUniswapPair(pair).initialize(token0, token1);
        //配对映射中设置token0=>token1=pair
        getPair[token0][token1] = pair;
        //配对映射中设置token1=>token0=pair
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        //配对数组中推入pair地址
        allPairs.push(pair);
    }

    // 设置收费人
    function setFeeTo(address _feeTo) override external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    /**
     * @dev 收税权限控制，转让权限
     * @param _feeToSetter 收税权限控制
     */
    function setFeeToSetter(address _feeToSetter) override external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}