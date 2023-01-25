// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Math.sol";
import "./ERC20.sol";

//设置IERC20的接口
interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract token is ERC20{

    //设置最小流动性
    uint256 constant MINIMUMLP = 1000;

    //币对里两个币的地址
    address public token0;
    address public token1;

    //token余额
    uint112 private reserve0;
    uint112 private reserve1;

    //防止重入攻击
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    //初始化
    constructor(address token0_ , address token1_) ERC20("zp", "ZP", 18) {
        token0 = token0_;
        token1 = token1_;
    }

    //添加流动性 或初始化
    function mint(uint256 token0amount, uint256 token1amount) public payable{

       //
       ERC20(token0).transferFrom(msg.sender ,address(this), token0amount);
       ERC20(token1).transferFrom(msg.sender ,address(this), token1amount);

        //获取池中原有余额
       (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        //获取币该地址在币对中的中的余额
       uint256 balance0 = IERC20(token0).balanceOf(address(this));
       uint256 balance1 = IERC20(token1).balanceOf(address(this));

        //求出池子中的币的余额
       uint256 amount0 = balance0 - _reserve0;
       uint256 amount1 = balance1 - _reserve1;

       //设置比例
       uint256 liquidity;

       //如果总量为0，则初始化
       //如果总量不为0，则为添加流动性
       if (totalSupply == 0) {
          liquidity = Math.sqrt(amount0 * amount1 ) - MINIMUMLP;
          _mint(address(0),MINIMUMLP);
       }else{
          //min确保添加时不按照比例添加，使得其中一个的Ratio增加获利
          liquidity = Math.min(
            (totalSupply * amount0) / _reserve0,
            (totalSupply * amount1) / _reserve1
          );
       }

       //流动性是否低于最小流动性
       require(liquidity > 0, "Less MINIMUMLP");

       //设置增加流动性地址的比例
       _mint(msg.sender , liquidity);

       //更新
       _update(balance0, balance1);
    }

    //移出流动性
    function burn(address to ) public returns(uint256 amount0, uint256 amount1) {

       //获取提取前币对余额
       uint256 balance0 = IERC20(token0).balanceOf(address(this));
       uint256 balance1 = IERC20(token1).balanceOf(address(this));

       //获取地址当时比例
       uint256 liquidity = balanceOf[address(this)];

       //计算提取的数量
       amount0 = liquidity * balance0 / totalSupply;
       amount1 = liquidity * balance1 / totalSupply;

       _burn(address(this),liquidity);
       _safeTransfer(token0 , to , amount0);
       _safeTransfer(token1 , to , amount1);

       balance0 = IERC20(token0).balanceOf(address(this));
       balance1 = IERC20(token1).balanceOf(address(this));

       //更新
       _update(balance0,balance1);

    }

    //交易
    //滑点 , 防止攻击lock或者可以使用Check
    //手续费
    function swap(uint256 amount0Out,uint256 amount1Out,address to) public lock{

        //检查
        require(amount0Out > 0 && amount1Out > 0);

        //获取交易前的余额
        (uint112 reserve0_ ,uint112 reserve1_, ) = getReserves();

        //防止提取超出余额
        require(amount0Out < reserve0_ || amount1Out <reserve1_);

        //修改池中的币
        uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

        //滑点，比较前后两次的k值来确定
        require (balance0 * balance1 > uint256(reserve0_) * uint256(reserve1_));

        //更新
        _update(balance0, balance1);

        //转账,手续费
        if (amount0Out > 0 ){
            uint256 amount0Out_ = amount0Out * 3 / 1000;
            _safeTransfer(token0, to, amount0Out_);
        }
        if (amount1Out > 0 ){
            uint256 amount1Out_ = amount1Out * 3 / 1000;
            _safeTransfer(token1, to, amount1Out_);
        }
    }

    //安全交易函数
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'tansfer error');
    }


    //更新余额函数
    function _update(uint256 balance0, uint256 balance1) private{
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
    }

    //获取余额函数
    function getReserves() public view returns(uint112,uint112,uint32){
        return (reserve0,reserve1,0);
    }


    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

}
