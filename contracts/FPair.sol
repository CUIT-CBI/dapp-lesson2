// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./Math.sol";
import './FT.sol';

contract FPair is FT, Math {

    uint256 constant MINIMUM_LIQUIDITY = 10;
    //新建两种代币
    address public token0;
    address public token1;
    //流动池中两种代币余额
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimes;
    //设定限制
    uint private lock =0;

    event Burn(address indexed sender,uint256 amount0,uint256 amount1, address to);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Swap(address indexed sender,uint256 amount0Out,uint256 amount1Out,address indexed to);

    modifier isLock(){
        require(lock ==0,"Unable use");
        lock=1;
        _;
        lock=0;
    }

    constructor() FT("FV2Pair", "FUNIV2") {}

    function initPair(address token0_, address token1_) public {
        require(token0 == address(0) && token1 == address(0));
        token0 = token0_;
        token1 = token1_;
    }

    function mint(address to) public returns (uint256 liquidity) {
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0_;
        uint256 amount1 = balance1 - reserve1_;
        //锁定最低流动性,防止有人刻意抬高流动性单价使得其他用户无法参与，无法停供流动性。 
        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(this), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply()) / reserve0_,
                (amount1 * totalSupply()) / reserve1_
            );
        }
        require(liquidity > 0);
        _mint(to, liquidity);
        _update(balance0, balance1);
        emit Mint(to, amount0, amount1);
    }

    function burn(address to) public returns (uint256 amount0, uint256 amount1){
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));
        amount0 = (liquidity * balance0) / totalSupply();
        amount1 = (liquidity * balance1) / totalSupply();
        require(amount0 != 0 && amount1 != 0);
        _burn(address(this), liquidity);

        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);

        emit Burn(msg.sender, amount0, amount1, to);
    }
    
    function _safeTransfer(address token,address to,uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        require(success || (data.length == 0 && abi.decode(data, (bool))));
    }

    function swap(uint256 amountAOut,uint256 amountBOut,address to) public isLock {
    
        require(amountAOut != 0 || amountBOut != 0);

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

        require(amountAOut <= reserve0_ && amountBOut <= reserve1_);

        if (amountAOut > 0) {
            _safeTransfer(token0, to, amountAOut);
        }
        if (amountBOut > 0) {
            _safeTransfer(token1, to, amountBOut);
        }
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0In = balance0 > reserve0 - amountAOut
        ? balance0 - (reserve0 - amountAOut): 0;
        uint256 amount1In = balance1 > reserve1 - amountBOut
        ? balance1 - (reserve1 - amountBOut): 0;

        require(amount0In != 0 || amount1In != 0, "Amount is not enough");

        // Adjusted = balance before swap - swap fee; fee stays in the contract
        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

        require(
            balance0Adjusted * balance1Adjusted >=
            uint256(reserve0_) * uint256(reserve1_) * (1000**2), "InvalidK");

        _update(balance0, balance1);
        emit Swap(msg.sender, amountAOut, amountBOut, to);
    }

    function getToken0() external view returns (address) {
        return token0;
    }

    function getToken1() external view returns (address) {
        return token1;
    }

    function getReserves() public view returns (uint112,uint112,uint32){
        return (reserve0, reserve1,blockTimes);
    }

    function getTokenReserve(address token) external view returns (uint112){
        if(token == token0) return reserve0;
        if(token == token1) return reserve1;
        return 0;
    }
    //准备金与余额匹配，按照余额匹配储备量进行更新
    function _update(uint256 balance0,uint256 balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max);
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

}
