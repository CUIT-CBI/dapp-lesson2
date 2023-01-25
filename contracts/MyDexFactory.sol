pragma solidity =0.5.16;
//主要参考资料：https://blog.csdn.net/zhoujianwei/article/details/124893129
import './interfaces/IMyDexFactory.sol';
import './MyDexPair.sol';

contract MyDexFactory is IMyDexFactory {
    address public feeTo;       //平台手续费收取的地址;
    address public feeToSetter;     //可设置平台手续费收取地址的地址;

    mapping(address => mapping(address => address)) public getPair;     //存放Pair合约两个token与Pair合约的地址;
    address[] public allPairs;      //存放所有Pair合约的地址;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {      //传入权限控制者的address；
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {        //查询Pair数组长度;
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'MyDex: IDENTICAL_ADDRESSES');        
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);   //对tokenA和tokenB进行大小排序,确保tokenA小于tokenB;
        require(token0 != address(0), 'MyDex: ZERO_ADDRESS');       //确认token0不等于0地址;
        require(getPair[token0][token1] == address(0), 'MyDex: PAIR_EXISTS');       //确认配对映射中不存在token0=>token1的映射;
        bytes memory bytecode = type(MyDexPair).creationCode;       //初始化Pair合约的字节码变量，bytecode是合约经过编译之后的源代码；
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));     //将token0和token1打包后创建哈希;
        assembly {      //内联汇编，通过create2方法布置合约，并且加salt，返回合约的地址是固定的，可预测的；
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IMyDexPair(pair).initialize(token0, token1);        //调用pair地址的合约的`initialine`方法，传入变量token0和token1；
        getPair[token0][token1] = pair;         //配对映射中设置token0=>token1 = pair;
        getPair[token1][token0] = pair;         //配对映射中设置token1=>token0 = pair
        allPairs.push(pair);        //配对数组中推入pair地址;
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {        //权限控制者合约设定平台手续费是否收取，以及收取的地址;
        require(msg.sender == feeToSetter, 'MyDex: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {        //原来的权限控制者，可以指派一个新的address作为新的权限控制者；
        require(msg.sender == feeToSetter, 'MyDex: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
