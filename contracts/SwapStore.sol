// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './SwapERC20.sol';
import './utils/Math.sol';
import './utils/IERC20.sol';

contract SwapStore is SwapERC20  {

    using Math for uint;
    uint public constant LIQUIDITY_LIMIT = 10**3;
    bytes4 private constant selector = bytes4(keccak256(bytes('transfer(address,uint256)')));
    address public factory;
    address public token0;
    address public token1;
    uint112 private reserve0;           
    uint112 private reserve1;           
    uint32  private blockTimestampLast; 
    uint public K;
    uint private unlocked = 1; 
    
    constructor() public {
        factory = msg.sender;
    }

    modifier lock() {
        require(unlocked == 1, "the store is being used");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    //获取当前交易对的资产信息和最后交易的区块时间
    function getReservesInfo() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    //使用call函数进行代币合约的transfer调用
    function _safeTransferFrom(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer faild");
    }

    //定义事件方便跟踪
    event Addliquidty(address indexed sender, uint amount0, uint amount1);
    event Reduceliquidty(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender,uint amount0In,uint amount1In,uint amount0Out,uint amount1Out,address indexed to);
    
    //进行合约的初始化
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "sender is not match"); 
        token0 = _token0;
        token1 = _token1;
    }

   
    //更新reverves，并且在每个block的第一次调用，更新价格累计值
    function _update(uint balance0, uint balance1) private {
        blockTimestampLast = uint32(block.timestamp % 2**32);
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        K = reserve0 * reserve1;
    }

   
   
    //增发流动性代币给提供者
    function addliquidty(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReservesInfo(); 
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        uint _totalSupply = totalSupply; 
        
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(LIQUIDITY_LIMIT);
           _mint(address(0), LIQUIDITY_LIMIT); 
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        _mint(to, liquidity);
        _update(balance0, balance1);
        emit Addliquidty(msg.sender, amount0, amount1);
    }

   
    //减少流动性
    function reduceliquidty(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReservesInfo();      
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
        uint _totalSupply = totalSupply; 
       
        amount0 = liquidity.mul(balance0) / _totalSupply; 
        amount1 = liquidity.mul(balance1) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, "amount must > 0");
        _burn(address(this), liquidity);
        _safeTransferFrom(token0, to, amount0);
        _safeTransferFrom(token1, to, amount1);
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1);
        emit Reduceliquidty(msg.sender, amount0, amount1, to);
    }

    
    //代币交换
    function swap(uint amount0Out, uint amount1Out, address to) external lock {
        require(amount0Out > 0 || amount1Out > 0, "amount must > 0");
        require(to != token0 && to != token1, "address cant be one of the token address");
        (uint112 _reserve0, uint112 _reserve1,) = getReservesInfo(); 
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "amount must less than the store");

        if (amount0Out > 0){
            _safeTransferFrom(token0, to, amount0Out); 
        }
        if (amount1Out > 0){
            _safeTransferFrom(token1, to, amount1Out);
        }  
 
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        //进行恒定乘积验证
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), "CPMM is error");
        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);

    }

    //强制交易对合约中两种代币的实际余额和保存的恒定乘积中的资产数量一致（多余的发送给合约调用者）
    function skimTransfer(address to) external lock {
        _safeTransferFrom(token0, to, IERC20(token0).balanceOf(address(this)).sub(reserve0));
        _safeTransferFrom(token1, to, IERC20(token1).balanceOf(address(this)).sub(reserve1));
    }

    //强制保存的恒定乘积的资产数量为交易对合约中两种代币的实际余额
    function syncTransfer() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }
}
