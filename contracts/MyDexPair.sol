pragma solidity =0.5.16;
//主要参考资料：https://blog.csdn.net/zhoujianwei/article/details/124893129

import './interfaces/IMyDexPair.sol';
import './interfaces/IERC20.sol';
import './interfaces/IMyDexFactory.sol';
import './interfaces/IMyDexCallee.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './MyDexERC20.sol';

contract MyDexPair is IMyDexPair, MyDexERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;     //最小流动性,1000
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    //SELECTOR为transfer(address,unit256)字符串哈希值的前4个字节,用于直接使用call方法调用token的转账方法;

    address public factory;     //工厂地址，存放工厂合约的地址
    address public token0;
    address public token1;      //token地址,存放两个token的地址

    uint112 private reserve0;           //储备量，当前pair合约所持有的token0数量；
    uint112 private reserve1;           //储备量，当前pair合约所持有的token1数量；
    uint32  private blockTimestampLast;     //blockTimestampLast用于判断是不是区块的第一笔交易；

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;       //价格最后累计，用于价格预言机上，该数值会在每个区块的第一笔交易进行更新；
    uint public kLast; //k值，即reserve0 * reserve1。
    //kLast变量在没有开启收费的时候，其值等于0，只有当开启平台收费的时候，这个值才等于k值；

    event Mint(address indexed sender, uint amount0, uint amount1);     //铸造
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);     //销毁
    event Swap(     //交换
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);     //同步

    uint private unlocked = 1;
    modifier lock() {       //锁定运行，防止重入攻击。
        require(unlocked == 1, 'MyDex: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {      //构造函数。pair合约是通过factory合约进行部署的，所以msg.sender的值就等于工厂合约的地址；
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {        //初始化方法。只在合约创建之后调用一次。
        require(msg.sender == factory, 'MyDex: FORBIDDEN');     //确认调用者为工厂地址；
        token0 = _token0;
        token1 = _token1;
    }
    /*
    因为pair合约是通过create2部署的，create2部署合约的特点就在于部署合约的地址是可预测的，并且后一次部署的合约可以把前一次
    部署的合约覆盖，这样可以实现合约的升级。如果想要实现升级，就需要构造函数不能有任何参数，这样才能让每次部署的地址都保持一致.
    所以要用initialize方法进行初始化，而不是在构造函数中。
    */

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
    /*
    获取储备量的方法。
    该方法返回token0的储备量，token1的储备量；blockTimestampLast代表上一个区块的时间戳。
    */
    
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();    //获取储备量0和储备量1；
        uint balance0 = IERC20(token0).balanceOf(address(this));        //获取当前合约在token0合约内的余额;
        uint balance1 = IERC20(token1).balanceOf(address(this));        //获取当前合约在token1合约内的余额;
        uint amount0 = balance0.sub(_reserve0);     //amount0 = 余额0 - 储备0
        uint amount1 = balance1.sub(_reserve1);     //amount1 = 余额1 - 储备1
        /*
        铸币过程发生在router合约向pair合约发送代币之后，因此此次的储备量和合约的token余额是不相等的，
        中间的差值就是需要铸币的token金额，即amount0和amount1。
        */
        bool feeOn = _mintFee(_reserve0, _reserve1);        //返回铸造费开关;
        uint _totalSupply = totalSupply;        //获取totalSupply;

        if (_totalSupply == 0) {        //如果是首次铸币，
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);     //流动性 = （数量0 * 数量1）的平方根 - 最小流动性1000
           _mint(address(0), MINIMUM_LIQUIDITY);        //在总量为0的初始状态，永久锁定最低流动性;
        /*
        当第一个人存入token的时候，并没有完全获得对应数量的LP token，有MININUM_LIQUIDITY数量的LP token被转入0地址销毁了。
        */
        } else {        //如果totalSupply初始不为0，则流动性应该如下计算：
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'MyDex: INSUFFICIENT_LIQUIDITY_MINTED');     //确定流动性大于0；
        _mint(to, liquidity);       //添加流动性(LP token)给to地址；
        _update(balance0, balance1, _reserve0, _reserve1);      //更新各储备量；
        if (feeOn) kLast = uint(reserve0).mul(reserve1);        //如果手续费开关为true,则更新k值 = 储备0 * 储备1
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();     //获取当前储备量0，储备量1；
        address _token0 = token0;                                
        address _token1 = token1;                                
        uint balance0 = IERC20(_token0).balanceOf(address(this));       //获取当前合约在token0合约内的余额；
        uint balance1 = IERC20(_token1).balanceOf(address(this));       //获取当前合约在token1合约内的余额;
        uint liquidity = balanceOf[address(this)];      //从当前合约的balanceOf映射中获取当前合约自身流动性数量;当前合约的余额是用户通过路由合约发送到pair合约要销毁的金额

        bool feeOn = _mintFee(_reserve0, _reserve1);        //返回手续费开关；
        uint _totalSupply = totalSupply;    //获取totalSupply
        amount0 = liquidity.mul(balance0) / _totalSupply;   
        amount1 = liquidity.mul(balance1) / _totalSupply;   //amount0和amount1是用户能取出多少来的数额；

        require(amount0 > 0 && amount1 > 0, 'MyDex: INSUFFICIENT_LIQUIDITY_BURNED');        //确认amount0和amount1都大于0;

        _burn(address(this), liquidity);        //销毁当前合约内的流动性数量;
        _safeTransfer(_token0, to, amount0);        //将amount0数量的_token0发送给to地址;
        _safeTransfer(_token1, to, amount1);        //将amount1数量的_token1发送给to地址;
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));        //更新balance0和balance1;
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1);    //和前面一样，更新储备量、更新k值；
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'MyDex: INSUFFICIENT_OUTPUT_AMOUNT');     //确认amount0Out和amount1Out都大于0；
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();        //获取储备量0和储备量1；
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'MyDex: INSUFFICIENT_LIQUIDITY');     //确认取出的量不能大于它的储备量;

        uint balance0;
        uint balance1;
        {           //用大括号限制了_toekn{0,1}的作用域，避免堆栈太深而出错；
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'MyDex: INVALID_TO');       //确保to地址不等于token0和token1的地址;
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);     //发送token0代币；
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);     //发送token1代币；
        if (data.length > 0) IMyDexCallee(to).myDexCall(msg.sender, amount0Out, amount1Out, data);      //如果data的长度大于0，就执行闪电贷调用;
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));        //余额0，1 = 当前合约在token0，1合约内的余额;
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        //如果余额0 > 大于储备0 - amount0Out，则amount0In = 余额0 - （储备0 - amount0Out）；否则amount0In = 0。后同。
        require(amount0In > 0 || amount1In > 0, 'MyDex: INSUFFICIENT_INPUT_AMOUNT');        //至少有一个大于0；
        {       //用大括号限制了_reserve{0,1}的作用域，避免堆栈太深而出错;
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));       //调整后的余额0 = 余额0 * 1000 - （amount0In * 3）
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));       //调整后的余额1 = 余额1 * 1000 - （amount1In * 3）
        /*实现收取千分之三手续费。*/
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'MyDex: K');
        //确保balance0Adjusted * balance1Adjusted >= 储备0 * 储备1 * 1000000
        }

        _update(balance0, balance1, _reserve0, _reserve1);      //同；
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function skim(address to) external lock {
        address _token0 = token0; 
        address _token1 = token1; 
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
        //将当前合约在token1,2的余额-储备量0，1安全发送到to地址上；
    }
    /*
    强制让余额等于储备量，一般用于储备量溢出的情况下，将多余的余额转出到address(to)上，使余额重新等于储备量。
    按照储备量匹配余额。
    */

    function sync() external lock {     //强制让储备量与余额对等。按照余额匹配储备量。
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _safeTransfer(address token, address to, uint value) private {     //只知道token合约地址就可以直接调用transfer方法;
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        //使用call方法直接调用对应token合约的transfer方法，获取返回值，需要判断返回值为true并且返回的data长度为0或者解码后为true;
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'MyDex: TRANSFER_FAILED');
    }

    
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'MyDex: OVERFLOW');     //确认余额0和余额1小于等于最大的uint112;
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);        //区块时间戳，将时间戳转换成uint32;
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;       //计算时间流逝;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {      //如果时间流逝>0，并且储备量0、1不等于0，也就是第一个调用,
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            //价格0最后累计 += 储备量1 * 2**112 / 储备量0 * 时间流逝，后同。
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);       //余额0，1放入储备量0，1;
        blockTimestampLast = blockTimestamp;        //更新最后时间戳;
        emit Sync(reserve0, reserve1);
    }
    /*
    更新储备量方法，主要用于每次添加流动性或者减少流动性之后调用；并在每一个区块的第一次调用时，更新价格累加器。
    */
    
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IMyDexFactory(factory).feeTo();     //查询工厂合约的feeTo变量值;
        feeOn = feeTo != address(0);        //如果feeTo不等于0地址，feeOn等于true;否则为false;
        uint _kLast = kLast;        //定义k值；
        if (feeOn) {        //if true
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));     //计算（_reserve0*_reserve1）的平方根;
                uint rootKLast = Math.sqrt(_kLast);     //计算k值的平方根;
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));     //分子 = erc20总量 * (rootK - rootKLast)
                    uint denominator = rootK.mul(5).add(rootKLast);     //分母 = rootK * 5 + rootKLast
                    uint liquidity = numerator / denominator;       //流动性 = 分子 / 分母
                    if (liquidity > 0) _mint(feeTo, liquidity);     //如果流动性 > 0 将流动性铸造给feeTo地址;
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }


}
