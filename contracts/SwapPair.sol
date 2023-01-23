// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Pair.sol';
import './SwapERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

contract SwapPair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;//最小流动性
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           
    uint112 private reserve1;           
    uint32  private blockTimestampLast; 

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;//恒定乘积值

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        // 设置 factory 地址
        factory = msg.sender;
    }

    //资金池状态
    function getReserves() public view returns (
        uint112 _reserve0, //token0的资金池数量
        uint112 _reserve1, //token1的资金池数量
        uint32 _blockTimestampLast//时间戳，上次更新库的时间
    ) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }


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
    event Sync(uint112 reserve0, uint112 reserve1);

    // 只有在合约部署的时候才能调用一次传入两个token的地址
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'forbidden'); // 检查地址
        token0 = _token0;
        token1 = _token1;
    }

    //更新资金池状态
    function _update(
        uint balance0, // token0 的余额
        uint balance1, // token1 的余额
        uint112 _reserve0, // token0 的资金池库存数量
        uint112 _reserve1 // token1 的资金池库存数量
    ) private {
        //需要两个token的余额不超过uint112的上限
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'overflow');
        //区块时间戳只取32位
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        //计算时间差timeElapsed
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    //手续费
    //_mintFee实现了添加和移除流动性的时候,向feeto地址发送手续费
    function _mintFee(
        uint112 _reserve0, //token0的资金池库存数量
        uint112 _reserve1 //token1的资金池库存数量
    ) private returns (
        bool feeOn//是否开启手续费
    ) {
        //获取手续费接收地址feeTo
        address feeTo = IUniswapV2Factory(factory).feeTo();
        //如果地址不为0则开启手续费接受
        feeOn = feeTo != address(0);
        uint _kLast = kLast; 
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
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    //提供流动性
    function mint(
        address to//LP接收地址
    ) external lock returns (
        uint liquidity//LP数量
    ) {
        //获取记录token库存
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
        //获取代币的余额balance0，balance1
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        //获取用户质押余额
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        //发送手续费
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            // LP 代币数量 liquidity = (amount0 * amount1)**2 - MINIMUM_LIQUIDITY
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            // 向全0地址发送数量为 MINIMUM_LIQUIDITY 的 LP 代币
           _mint(address(0), MINIMUM_LIQUIDITY); 
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'imsuffucient_liquidity_minted');
        //向to地址发送数量为liquidity的流动性
        _mint(to, liquidity);

        //更新库存
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Mint(msg.sender, amount0, amount1);
    }


    //移除流动性
    function burn(
        address to//资产接收地址
    ) external lock returns (
        uint amount0, //获取token0的数量
        uint amount1//获取token1的数量
    ) {
        // 获取记录库存 _reserve0，_reserve1
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // 获取 _token0，_token1
        address _token0 = token0;                                
        address _token1 = token1;     
        //获取代币余额balance0,balance1                           
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        //获取liquidity流动性
        uint liquidity = balanceOf[address(this)];
        //发送手续费
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; 

        amount0 = liquidity.mul(balance0) / _totalSupply; 
        amount1 = liquidity.mul(balance1) / _totalSupply; 

        require(amount0 > 0 && amount1 > 0, 'imsuffucient_liquidity_burned');
        //销毁liquidity数量的LP代币
        _burn(address(this), liquidity);
        //转账
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        //更新余额
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        //更新库存
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Burn(msg.sender, amount0, amount1, to);
    }

    //实现交易功能
    function swap(
        uint amount0Out,//预期获得的token0数量
        uint amount1Out,//预期获得的token1数量
        address to,//资产接收地址
        bytes calldata data//闪电贷调用数据
    ) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'insufficient_output_amount');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'insufficient_liquidity');

        uint balance0;
        uint balance1;
        { 
        address _token0 = token0;   
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'invalid_to');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); 
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); 
        //如果data.length>0,执行闪电贷
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        //获取token余额
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'insufficient_input_amount');
        { 
            // 需要交易之后的 K 值不能变小
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= 
            uint(_reserve0).mul(_reserve1).mul(1000**2), 'k');
        }
        //更新库存
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    //再平衡函数
    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        // 将多于库存 reserve0 的代币 _token0 发送到 to 地址
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        // 将多于库存 reserve1 的代币 _token1 发送到 to 地址
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    //更新库存
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)), 
            IERC20(token1).balanceOf(address(this)), 
            reserve0, reserve1
        );
    }
}
