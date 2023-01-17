pragma solidity =0.5.16;

import './interfaces/ITLWPair.sol';
import './TLWERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/ITLWFactory.sol';
import './interfaces/ITLWCallee.sol';

contract TLWPair is ITLWPair, TLWERC20 {
    using SafeMath for  uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;//工厂地址
    address public token0;//token0地址
    address public token1;//token1地址

    uint112 private reserve0;//token0的储备量
    uint112 private reserve1;//token1的储备量
    uint32 private blockTimestampNewest;//最后时间戳

    // uint public price0CumulativeLast;//价格0最后累计
    // uint public price1CumulativeLast;//价格1最后累计
    uint public kLast;//此k值为最近流动新事件后的k值，是0、1储备量之乘积
    uint private unlocked =1;
    modifier lock() {
        require(unlocked ==1, '交易已锁定');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, '权限不足:仅工厂合约可调用该方法');
        token0 = _token0;
        token1 = _token1;
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns(bool feeOn) {
        address feeTo = ITLWFactory(factory).feeTo();
        if(feeTo != address(0)){
            feeOn = true;
        }else{ feeOn = false;}
        uint256 _kLast = kLast;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));//计算储备量乘积的平方根
                uint256 rootKLast = Math.sqrt(_kLast);//计算k值的平方根
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    //最终算式中的分子部分
                    uint denominator = rootK.mul(5).add(rootKLast);
                    //最终算式中的分母部分
                    uint liquidity = numerator / denominator;//合并算式
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        }else if (_kLast != 0) {
            kLast = 0;
        }
    }
    function _update(
    uint balance0, 
    uint balance1, 
    uint112 _reserve0, 
    uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), '数据溢出');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        // uint32 timeElapsed = blockTimestamp - blockTimestampNewest;//计算出距上次上传后相差时间
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampNewest = blockTimestamp;
        emit Sync(reserve0,reserve1);
    }

    function getReserves() public view returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampNewest) {
            _reserve0 = reserve0;
            _reserve1 = reserve1;
            _blockTimestampNewest = blockTimestampNewest;
        }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data,(bool))), '交易失败！');
    }

    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);//返回铸造费开关
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            //流动性 = （数量0 * 数量1）开方 - 最小流动性（1000）
            _mint(address(0), MINIMUM_LIQUIDITY);//在总量为零的初始状态，永久锁定最低流动性
        }else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, '铸造的流动性不足!');
        _mint(to,liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1);//更新储备量
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external lock returns(
        uint256 amount0, uint256 amount1
    ){
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        amount0 = liquidity.mul(balance0) / _totalSupply;
        amount1 = liquidity.mul(balance1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, '流动性已被销毁');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to ,amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if(feeOn) kLast = uint(reserve0).mul(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(
        uint amount0Out,
        uint amount1Out, 
        address to, 
        bytes calldata data)
     external lock {
        require(amount0Out > 0 || amount1Out > 0, '请输入正确的交易数量');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, '流动性小于取出量，请重试');

        uint balance0;
        uint balance1;
        {
            address _token0 = token0;
            address _token1 = token1;

            require(to != _token0 && to != _token1, '非法的to地址');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);

            if (data.length > 0)
                ITLWCallee(to).TLWCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );//闪电贷的实现
                balance0 = IERC20(_token0).balanceOf(address(this));
                balance1 = IERC20(_token1).balanceOf(address(this));
        }//作用域，防止堆栈太深导致gasfee超标

        uint amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve0 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            'INPUT参数违法'
        );
        {
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));

            require(
                balance0Adjusted.mul(balance1Adjusted) >= 
                uint(_reserve0).mul(_reserve1).mul(1000**2),
                '不符合k值'
            );//确认路由合约中已收过手续费
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0,
            to,
            IERC20(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }//强制将多余的储备量发送给to地址，强制平衡以匹配储备

    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }//强制将储备量与余额进行匹配
}


