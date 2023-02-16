// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./UniswapERC20.sol";
import './libraries/Math.sol';
contract CsdswapPair is CsdswapERC20{
    
    using SafeMath  for uint;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    address public factory;
    address public token0;
    address public token1;
    

    constructor() public {
        factory = msg.sender;
    }

    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }



    // 增加流动性
    function addLiquidity(address to,uint amount0,uint amount1) returns(uint liquidity){
        uint256 totalSupply=_totalSupply;
        uint _reserve0=IERC20(token0).balanceOf(address(this));
        uint _reserve1=IERC20(token1).balanceOf(address(this));
        transfer2(amount0, amount1);
        if(totalSupply==0){
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        }else{
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        emit Mint(msg.sender, amount0, amount1);
    }
    
    function transfer2(uint256 amount0,uint256 amount1)private{
       require(IERC20(token0).transferFrom(msg.sender,address(this),amount0),"token0 trasfer failed");
       require(IERC20(token1).transferFrom(msg.sender,address(this),amount1),"token1 trasfer failed");
    }
    
    function removeLiquidity(uint256 liquidity)public returns(uint256,uint256){
        uint _reserve0=IERC20(token0).balanceOf(address(this));
        uint _reserve1=IERC20(token1).balanceOf(address(this));
        uint256 amount0=liquidity/_totalSupply*_reserve0;
        uint256 amount1=liquidity/_totalSupply*_reserve1;
        _burn(msg.sender,liquidity);
        transferOut(amount0, amount1);
        return amount0,amount1;
    }

    function transferOut(uint256 amount0,uint256 amount1) private{
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);
    }

    function swap(address token,uint256 amount)public {
        require(token==token1 || token==token0);
        uint _reserve0=IERC20(token0).balanceOf(address(this));
        uint _reserve1=IERC20(token1).balanceOf(address(this));
        uint256 _newAmount=newAmount(amount);
        swapFrom(token, amount);
        if(token==token1){
            uint256 amountTo=_reserve0-(_reserve0*_reserve1)/(_reserve1+_newAmount)
            swapTo(token0,amountTo);
        }else{
            uint256 amountTo=_reserve1-(_reserve0*_reserve1)/(_reserve0+_newAmount)
            swapTo(token1,amountTo);
        }
    }

    function swapFrom(address token,uint256 amount)private {
        require(IERC20(token).transferFrom(msg.sender,address(this),amount));
    }

    function swapTo(address token,uint256 amount)private{
       IERC20(token).transfer(msg.sender, amount);
    }
    function newAmount(uint256 amount)private{
        uint256 fee=CsdswapFactory(factory).feePercentage();
        return amount*(1000-fee)/1000;
    }
}

