pragma solidity =0.5.16;

import "https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol";

import "https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol";  

contract pair is IUniswapV2Pair, UniswapV2ERC20 {
 uint public constant MINIMUM_LIQUIDITY = 10**3;
 bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
 address token0;
 address token1;
 address factory;
uint112  _reserve0;
uint112  _reserve1;
uint public kLast;
uint public price0CumulativeLast;
uint public price1CumulativeLast;
uint32   blockTimestampLast;
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
constructor()public{
    
}

function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }
  function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
           
        }
        _reserve0 = uint112(balance0);
        _reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
       
    }

    function _getReserves() public  returns (uint112 reserve0, uint112 reserve1, uint32 _blockTimestampLast) {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        _blockTimestampLast = blockTimestampLast;
        return(reserve0,reserve1,_blockTimestampLast);
    }

function initialize(address _token0, address _token1) external {
    // 确认调用者为工厂地址
    require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
    token0 = _token0;
    token1 = _token1;
}

uint private inlock=1;
modifier lock(){
   require(inlock==1,"is locked");
   inlock=0;
   _;
   inlock=1;
}
function mint(address to) external lock returns (uint liquidity) {
    // 获取储备量0和储备量1
   (uint112 _reserve0, uint112 _reserve1,) = _getReserves(); // gas savings
    // 获取当前合约在token0合约内的余额
    uint balance0 = IERC20(token0).balanceOf(address(this));
    // 获取当前合约在token1合约内的余额
    uint balance1 = IERC20(token1).balanceOf(address(this));
    // amount0 = 余额0 - 储备0
    uint amount0 = balance0.sub(_reserve0);
    // amount1 = 余额1 - 储备1
    uint amount1 = balance1.sub(_reserve1);

    // 返回铸造费开关
   // bool feeOn = _mintFee(_reserve0, _reserve1);
    // 获取totalSupply
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    // 如果_totalSupply等于0
    if (_totalSupply == 0) {
        // 流动性 = （数量0 * 数量1）的平方根 - 最小流动性1000
        liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
        // 在总量为0的初始状态，永久锁定最低流动性
        _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
    } else {
        // 流动性 = 最小值（amount0 * _totalSupply / _reserve0 和 (amount1 * _totalSupply) / reserve1）
        liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
    }
    // 确认流动性 > 0
    require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
    // 铸造流动性给to地址
    _mint(to, liquidity);

    // 更新储备量
    //unipair._update(balance0, balance1, _reserve0, _reserve1);
    // 如果铸造费开关为true,k值 = 储备0 * 储备1
     kLast = uint(_reserve0).mul(_reserve1); // reserve0 and reserve1 are up-to-date
    // 触发铸造事件
    emit Mint(msg.sender, amount0, amount1);
}
function burn(address to) external lock returns (uint amount0, uint amount1) {
    // 获取储备量0，储备量1
   (uint112 _reserve0, uint112 _reserve1,) =_getReserves(); // gas savings
    // 带入变量
    address _token0 = token0;                                // gas savings
    address _token1 = token1;                                // gas savings
    // 获取当前合约在token0合约内的余额
    uint balance0 = IERC20(_token0).balanceOf(address(this));
    // 获取当前合约在token1合约内的余额
    uint balance1 = IERC20(_token1).balanceOf(address(this));
    // 从当前合约的balanceOf映射中获取当前合约自身流动性数量
    // 当前合约的余额是用户通过路由合约发送到pair合约要销毁的金额
    uint liquidity = balanceOf[address(this)];

    // 返回铸造费开关
    //bool feeOn = _mintFee(_reserve0, _reserve1);
    // 获取totalSupply
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    // amount0和amount1是用户能取出来多少的数额
    // amount0 = 流动性数量 * 余额0 / totalSupply 使用余额确保按比例分配
    // 取出来的时候包含了很多个千分之三的手续费
    amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
    // amount1 = 流动性数量 * 余额1 / totalSupply 使用余额确保按比例分配
    amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
    // 确认amount0和amount1都大于0
    require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
    // 销毁当前合约内的流动性数量
    _burn(address(this), liquidity);
    // 将amount0数量的_token0发送给to地址
    
    //unipair._safeTransfer(_token0, to, amount0);
    // 将amount1数量的_toekn1发给to地址

    _safeTransfer(_token1, to, amount1);
    // 更新balance0和balance1
    balance0 = IERC20(_token0).balanceOf(address(this));
    balance1 = IERC20(_token1).balanceOf(address(this));

    //unipair._update(balance0, balance1, _reserve0, _reserve1);
    //if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
    emit Burn(msg.sender, amount0, amount1, to);
    }
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = _getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
}
