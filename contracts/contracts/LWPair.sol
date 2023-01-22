pragma solidity =0.5.16;

import './interfaces/ILWPair.sol';
import './LWERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/ILWFactory.sol';
import './interfaces/ILWCallee.sol';

contract LWPair is ILWPair, LWERC20 {
    //指定库函数的类型
    using SafeMath  for uint;
    using UQ112x112 for uint224;//赋予uint224是因为solidity里面没有非整型的类型，但是token的数量会出现小数位

   //定义了最小流动性，是最小数值1的1000倍
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    //用于直接使用call方法调用token的转账方法
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;//记录合约地址
    address public token0;//记录代币0的地址
    address public token1;//记录代币1的地址
    uint32  public blockTimestampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;
    

    uint112 private reserve0;//最新的资产数量          
    uint112 private reserve1;//最新的资产数量           
    
    //用来获取当前交易对的资产数量以及最后交易的区块时间
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    //使用call函数进行代币合约transfer的调用
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
   );
    event Sync(uint112 reserve0, uint112 reserve1);//同步事件
    event Split(uint splitPoint);//滑点

    
    // 锁定变量，防止重入
    uint private unlocked = 1;

    modifier lock() {
    require(unlocked == 1, 'UniswapV2: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
    }

    //构造器：记录factory合约的地址
    constructor() public {
        factory = msg.sender;
    }

    //合约初始化，记录两种代币的地址,创建交易池
    function initialize(address _token0, address _token1) external {
       //确认调用者为工厂地址
        require(msg.sender == factory, 'LiuWei: FORBIDDEN'); 
        token0 = _token0;
        token1 = _token1;
    } 
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
           
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

     //增加流动性
    function mint(address to) external lock returns (uint liquidity) {
    
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
    // 获取当前合约在token0合约内的余额
    uint balance0 = IERC20(token0).balanceOf(address(this));
    // 获取当前合约在token1合约内的余额
    uint balance1 = IERC20(token1).balanceOf(address(this));
    // amount0 = 余额0 - 资产0
    uint amount0 = balance0.sub(_reserve0);
    // amount1 = 余额1 - 资产1
    uint amount1 = balance1.sub(_reserve1);
 
    
    uint _totalSupply = totalSupply; 
    // 如果_totalSupply等于0
    if (_totalSupply == 0) {
        //计算流动性
        liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
        // 在总量为0的初始状态，永久锁定最低流动性
        _mint(address(0), MINIMUM_LIQUIDITY); 
    } else {
    
        liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
    }
    // 确认流动性 > 0
    require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
    // 铸造流动性给to地址
    _mint(to, liquidity);
 
    // 更新储备量
    _update(balance0, balance1, _reserve0, _reserve1);
   
    // 触发铸造事件
    emit Mint(msg.sender, amount0, amount1);
}

    //移除流动性
   function burn(address to) external lock returns (uint amount0, uint amount1) {
 
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
    address _token0 = token0;                                
    address _token1 = token1;                              
    // 获取当前合约在token0合约内的余额
    uint balance0 = IERC20(_token0).balanceOf(address(this));
    // 获取当前合约在token1合约内的余额
    uint balance1 = IERC20(_token1).balanceOf(address(this));

    uint liquidity = balanceOf[address(this)];
 
    uint _totalSupply = totalSupply; 
    // amount0和amount1是用户能取出来多少的数额
    // amount0 = 流动性数量 * 余额0 / totalSupply 使用余额确保按比例分配
    // 取出来的时候包含了很多个千分之三的手续费
    amount0 = liquidity.mul(balance0) / _totalSupply;
  
    amount1 = liquidity.mul(balance1) / _totalSupply; 
    // 确认amount0和amount1都大于0
    require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
    // 销毁当前合约内的流动性数量
    _burn(address(this), liquidity);

    // 将amount数量的_token发送给to地址
    _safeTransfer(_token0, to, amount0);
    _safeTransfer(_token1, to, amount1);

    // 更新balance0和balance1
    balance0 = IERC20(_token0).balanceOf(address(this));
    balance1 = IERC20(_token1).balanceOf(address(this));
 
    _update(balance0, balance1, _reserve0, _reserve1);
    emit Burn(msg.sender, amount0, amount1, to);
    }

  
    //滑点，手续费，交易功能
   function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
    // 确认amount0Out和amount1Out都大于0
    require(amount0Out > 0 || amount1Out > 0, 'LW: INSUFFICIENT_OUTPUT_AMOUNT');
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
    // 确认取出的量不能大于它的 储备量
    require(amount0Out < _reserve0 && amount1Out < _reserve1, 'LW: INSUFFICIENT_LIQUIDITY');
 
    // 初始化变量
    uint balance0;
    uint balance1;
    { 
       
    address _token0 = token0;
    address _token1 = token1;
    // 确保to地址不等于token0和token1的地址
    require(to != _token0 && to != _token1, 'LW: INVALID_TO');
    // 发送token代币
    if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
    if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); 
   
   
    // 当前合约在token0，1合约内的余额
    balance0 = IERC20(_token0).balanceOf(address(this));
    balance1 = IERC20(_token1).balanceOf(address(this));
    }
    // 如果余额0 > 大于储备0 - amount0Out 则 amount0In = 余额0 - （储备0 - amount0Out） 否则amount0In = 0
    uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
    uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
    // 确保输入数量0｜｜1大于0
    require(amount0In > 0 || amount1In > 0, 'LW: INSUFFICIENT_INPUT_AMOUNT');
    { 
    // 调整后的余额= 余额 * 1000 - （amountIn * 3），千分之三手续费
    uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
    uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
    // 确保balance0Adjusted * balance1Adjusted >= 储备0 * 储备1 * 1000000
    require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'LW: K');
    }

    //滑点计算
    uint splitPoint = math.abs(amount0In.sub(amount0Out)).mul(100).div(reserve0);
    emit Split(splitPoint);
    // 更新储备量
    _update(balance0, balance1, _reserve0, _reserve1);
    // 触发交换事件
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
}
    
}


    
