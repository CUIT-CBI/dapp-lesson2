// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./FT.sol";
// import "./Math.sol";

contract TokenSwap is ERC20{
    address public owner;

    address public tokenA;// tokenA合约地址
    address public tokenB;// tokenB合约地址

    uint256 public amountA;// tokenA数量
    uint256 public amountB;// tokenB数量

    uint public  liquidity; //流动性

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    //在构造函数中声明并且保存这两个地址
    //这个合约本身也会产生一个 ERC-20 代币
    constructor(address _tokenA, address _tokenB) ERC20("LP", "LP") {        
        tokenA = _tokenA;
        tokenB = _tokenB;
        owner = msg.sender;
    }

    function updateAmount() public {
        amountA = ERC20(tokenA).balanceOf(address(this));
        amountB = ERC20(tokenB).balanceOf(address(this));
    }

        function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // 初始化池子
    function initPool(uint256 _amountA, uint256 _amountB) public {
        ERC20(tokenA).transferFrom(msg.sender, address(this), _amountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), _amountB);
        updateAmount();
        uint initLiquidity = Math.sqrt(amountA * amountB);
        _mint(msg.sender, initLiquidity);
    }

    // 增加流动性
     function addLiquidity(address _token, uint256 _amount) 
        external
        returns (uint256) 
    {

        if(_token == tokenA){
            ERC20(tokenA).transferFrom(msg.sender, address(this), _amount);
            ERC20(tokenB).transferFrom(msg.sender, address(this), _amount * amountB / amountA);       
        } else if(_token == tokenB){
            ERC20(tokenA).transferFrom(msg.sender, address(this), _amount * amountA / amountB);
            ERC20(tokenB).transferFrom(msg.sender, address(this), _amount);   
        }else {
            revert("Wrong address");
        }

        liquidity = Math.min(totalSupply() * amountA / amountA, totalSupply() * amountB / amountA);
        _mint(msg.sender, liquidity);

        updateAmount();

        return liquidity;
    }

    // 移除流动性
    function removeLiquidity(uint256 _liquidity) 
        external 
        payable 
        returns (uint256, uint256)
    {
        require(_liquidity > 0 );

        uint256 balanceA = ERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this));

        amountA = _liquidity * balanceA / totalSupply();       
        amountB = _liquidity * balanceB / totalSupply();
        _burn(msg.sender, _liquidity);

        ERC20(tokenA).transfer(msg.sender, amountA);
        ERC20(tokenB).transfer(msg.sender, amountB);

        updateAmount();

        return (amountA, amountB);
    }

    //用A换B
    function swapAtoB(uint256 _amountA)
        public
        payable
        returns (uint256)
    {
        ERC20(tokenA).transferFrom(msg.sender, address(this), _amountA);
        uint256 _amountB = amountB - (amountA * amountB) / (amountA + _amountA  * 997 / 1000);   // 千分之三手续费
        ERC20(tokenB).transfer(msg.sender, _amountB);
        updateAmount();
        return _amountB;
    }



    // 用B换A 
    function swapBtoA(uint256 _amountB)
        public
        payable
        returns (uint256)
    {
        ERC20(tokenB).transferFrom(msg.sender, address(this), _amountB);
        uint256 _amountA = amountA - (amountB * amountA) / (amountB + _amountB * 997 / 1000);   // 千分之三手续费
        ERC20(tokenA).transfer(msg.sender, _amountA);
        updateAmount();
        return _amountA;
    }

    //设置滑点
    function SwapSlippageLimit(address _token, uint256 _amount, uint256 slippageLimit) external returns (uint256){
        require(_token == tokenA || _token == tokenB);
        uint256 expectGetAmount;
        uint256 actualGetAmount;

        if(_token == tokenA){
            expectGetAmount = _amount * amountB / amountA;
            actualGetAmount = swapAtoB(_amount);
        }
        if(_token == tokenB){
            expectGetAmount = _amount  * amountA /amountB;
            actualGetAmount = swapBtoA(_amount);
        }
        uint256 slippage = (expectGetAmount - actualGetAmount) * 1000 / expectGetAmount;
        require(slippage <= slippageLimit);

        updateAmount();
        return slippage;
    }



}