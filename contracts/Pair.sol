// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./libraries/SafeMath.sol";
import "./libraries/UQ112x112.sol";
import './libraries/Math.sol';
import "./Factory.sol";
import "./ERC20.sol";
import "./FT.sol";
contract Pair is UniswapV2ERC20{
    using SafeMath  for uint;
    using UQ112x112 for uint224;
    address public factory;
    // 最低流动性
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    // 获取transfer方法的bytecode前四个字节
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves  == 使用单个存储槽，可通过 getReserves 访问
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;   // 最后价格累计的 0 价格 ？
    uint public price1CumulativeLast;

    // 紧接最近一次流动性事件之后
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;

    // 防止递归迭代出现问题，所以要上锁
    //一个锁，使用该modifier的函数在unlocked==1时才可以进入，
    //第一个调用者进入后，会将unlocked置为0，此使第二个调用者无法再进入
    //执行完_部分的代码后，才会再将unlocked置1，重新将锁打开
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // 获取储备: 返回： _reserve0, _reserve1, _blockTimestampLast
    // 用于获取两个token在池子中的数量和最后更新的时间
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        // 时间戳
        _blockTimestampLast = blockTimestampLast;
    }

    // 转账，安全校验
    function _safeTransfer(address token, address to, uint value) private {
        // 调用transfer方法，把地址token中的value个coin转账给to
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        // 检查返回值，必须成功否则报错
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender,uint amount0In,uint amount1In,uint amount0Out,uint amount1Out,address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    //部署此合约时将msg.sender设置为factory，后续初始化时会用到这个值
    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    // 在UniswapV2Factory.sol的createPair中调用过
    function initialize(address _token0, address _token1) external {
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    // 更新储备，并在每个区块的第一次调用时更新价格累加器
    /**
        更新变量：
            blockTimestampLast
            reserve0
            reserve1
            price0CumulativeLast
            price1CumulativeLast
     */
     // 这个函数是用来更新价格oracle的，计算累计价格
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        // 溢出校验
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // 计算时间加权的累计价格，256位中，前112位用来存整数，后112位用来存小数，多的32位用来存溢出的值
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        // 更新reserve值
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }
   
    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    // 如果收费，增发流动性相当于 sqrt(k) 增长的 1/6
    function _mintFee(uint112 _reserve0, uint112 _reserve1) public returns (bool feeOn,address feeTo) {
        // 获取接收手续费的地址
        address feeTo = Factory(factory).getFeeTo();
        // 手续费接收者不为0地址
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        // 手续费接收者不为0地址
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                  if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        }
        // 手续费接收者为0， 并且kLast 不为 0
        else if (_kLast != 0) {
            kLast = 0;
        }
    }
    
    // this low-level function should be called from a contract which performs important safety checks
    // 这个低级函数应该从执行重要安全检查的合约中调用
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        // 合约里两种token的当前的balance
        uint balance0 = FT(token0).balanceOf(address(this));
        uint balance1 = FT(token1).balanceOf(address(this));
        // 获得当前balance和上一次缓存的余额的差值
        // 因为balance是动态变化的，reserve是静态变化的
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        // 计算手续费
        // bool feeOn = _mintFee(_reserve0, _reserve1);
        // gas 节省，必须在此处定义，因为 totalSupply 可以在 _mintFee 中更新
        // totalSupply 是 pair 的凭证
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            // 第一次铸币，也就是第一次注入流动性，值为根号k减去MINIMUM_LIQUIDITY，防止数据溢出
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            // 把MINIMUM_LIQUIDITY赋给地址0，永久锁住
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            // 计算增量的token占总池子的比例，作为新铸币的数量
            // 木桶法则，按最少的来，按当前投入的占池子总的比例增发
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        // 铸币，修改to的token数量及totalsupply
        // 给to地址发凭证，同时pair合约的totalSupply增发同等的凭证
        _mint(to, liquidity);
        // 更新时间加权平均价格
        _update(balance0, balance1, _reserve0, _reserve1);
        // if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = FT(_token0).balanceOf(address(this));
        uint balance1 = FT(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        // bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        // 计算返回的 amount0/1
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this),liquidity);
        // _token0/1 给 to 转 amount0/1
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        // 获取转账后的balance
        balance0 = FT(_token0).balanceOf(address(this));
        balance1 = FT(_token1).balanceOf(address(this));
        // 更新 reserve0, reserve1 和 时间戳
        _update(balance0, balance1, _reserve0, _reserve1);
        // if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // 交易函数
    // 可以是   token0 --> token1,
    // 也可以是 token1 --> token0
    // 但 参数中：amount0Out 和 amount1Out 中有一个值是0
    function swap(
        uint amount0Out, 
        uint amount1Out, 
        address to, 
        bytes calldata data
    ) external lock 
    {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        // 划转操作
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        
        // if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = FT(_token0).balanceOf(address(this));
        balance1 = FT(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        // 防止数据溢出校验
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        // 更新
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    // 强制balance以匹配储备
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, FT(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, FT(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    // 强制储备以匹配balance
    function sync() external lock {
        _update(FT(token0).balanceOf(address(this)), FT(token1).balanceOf(address(this)), reserve0, reserve1);
    }

}