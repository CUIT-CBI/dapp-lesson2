// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './UniSwapV2ERC20.sol';
import './FT.sol';
import './libraries/SafeMath.sol';
import './libraries/Math.sol';


contract MyUniswapPair is FT {
    using SafeMath for uint;

    uint public constant MINIMUM_LIQUIDITY = 10**3;//定义最小流动性

    //计算ERC20合约中转代币函数transfer的函数选择器，用于_safeTransfer函数
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    //address public factory;
    address public token0;
    address public token1;

    uint private reserve0;           // token0余额
    uint private reserve1;           // token1余额
    uint32  private blockTimestampLast; //记录交易时间


    constructor(address _token0,address _token1) FT("MyUniswap","CKR") {
        require(_token0 != address(0) && _token1 != address(0), 'MyUniswap: NULL_ADDRESS');
        token0 = _token0;
        token1 = _token1;
    }
    
    //防止重入攻击
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'MyUniswap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    //获取交易对的资产信息和记录最后交易的区块时间
    function getReserves() public view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'MyUniswap: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    
    // 更新reserve
    function _update(uint balance0, uint balance1, uint _reserve0, uint _reserve1) private {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        reserve0 = uint(balance0);
        reserve1 = uint(balance1);
        blockTimestampLast = blockTimestamp;
        
    }

    // 增发流动性
    function addLiquidity(address to) external lock returns (uint liquidity) {
        (uint _reserve0, uint _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);


        uint _totalSupply = totalSupply; 

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'MyUniswap: INSUFFICIENT_LIQUIDITY');//增加的流动性需大于0
        _mint(to, liquidity);


        emit Mint(msg.sender, amount0, amount1);
    }

    // 移除流动性
    function removeLiquidity(address to) external lock returns (uint amount0, uint amount1) {
        (uint _reserve0, uint _reserve1,) = getReserves(); 
        //为了节省gas，会保存在局部变量中
        address _token0 = token0;                                
        address _token1 = token1;    

        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; 
        amount0 = liquidity.mul(balance0) / _totalSupply; 
        amount1 = liquidity.mul(balance1) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'MyUniswap: INSUFFICIENT_LIQUIDITY');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }
    
    //交易功能
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'MyUniswap: INSUFFICIENT_OUTPUT_AMOUNT'); //输入参数不为0
        (uint _reserve0, uint _reserve1,) = getReserves(); 
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'MyUniswap: INSUFFICIENT_LIQUIDITY');//校验购买的数量小于reverse
        
        uint balance0;
        uint balance1;
        address _token0 = token0;
        address _token1 = token1;
        uint Fee_Premium = 3/1000;//手续费

        require(to != _token0 && to != _token1, 'MyUniswap: INVALID_TO');
        if (amount0Out > 0 ) {
            uint256 _amount0Out = amount0Out - amount0Out * Fee_Premium;
            _safeTransfer(_token0, to, _amount0Out);
        } 
        if (amount1Out > 0 ) {
            uint256 _amount1Out = amount1Out - amount1Out * Fee_Premium;
            _safeTransfer(_token1, to, _amount1Out);
        }

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
    
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0Out, amount1Out, to);
    }

}