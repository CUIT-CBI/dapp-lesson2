// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FT.sol";

contract UniswapPair is FT {
    address public factory;//工厂地址

    address public tokenA;//tokenA地址
    address public tokenB;//tokenB地址

    uint256 public reserveA;//tokenA的储备量
    uint256 public reserveB;//tokenB的储备量

    uint8 public charge; //单位是万分之几，千分之三的手续费就是30

    bool public initialized = false;

    constructor(address _tokenA, address _tokenB) FT("WQYUniSwap LPToken", "LP") {
        tokenA = _tokenA;
        tokenB = _tokenB;
        factory = msg.sender;
    }

    function sync(address account) external {
        require(msg.sender == factory, "WQYUniSwap: not factory!");
        _updateReserves();
        super._mint(account, reserveA * reserveB);
    }

    //增加流动性
    function addFlowability(uint256 count) external {
        address account = msg.sender;
        uint256 currentLPTotalSupply = totalSupply();

        require(currentLPTotalSupply > 0, "WQYUniSwap: Invalid lp token count reserved.");

        uint256 _tokenACount = reserveA * count / currentLPTotalSupply;
        uint256 _tokenBCount = reserveB * count / currentLPTotalSupply;

        ERC20(tokenA).transferFrom(account, address(this), _tokenACount);
        ERC20(tokenB).transferFrom(account, address(this), _tokenBCount);

        super._mint(account, count);

        _updateReserves();
    }

    //移出流动性
    function removeFlowability(uint256 count) external {
        address account = msg.sender;
        uint256 currentLPTotalSupply = totalSupply();

        require(balanceOf(account) >= count, "WQYUniSwap: You don't have enough lp token.");
        require(currentLPTotalSupply > count, "WQYUniSwap: Invalid lp token count to remove.");

        uint256 _tokenACount = reserveA * count / currentLPTotalSupply;
        uint256 _tokenBCount = reserveB * count / currentLPTotalSupply;

        ERC20(tokenA).transfer(account, _tokenACount);
        ERC20(tokenB).transfer(account, _tokenBCount);

        super._burn(account, count);

        _updateReserves();
    }

    //交易+滑点+手续费功能
    function swap(uint256 _amountAIn, uint256 _amountBIn, uint256 _amountAOutMin, uint256 _amountBOutMin) external {
        uint256 amountAOut;
        uint256 amountBOut;
        address account = msg.sender;

        //滑点
        if(_amountAIn > 0) {
            amountBOut = reserveB - reserveA * reserveB / (reserveA + _amountAIn);
            amountBOut = amountBOut - amountBOut * charge/10000;
        } else {
            amountAOut = reserveA - reserveA * reserveB / (reserveB + _amountBIn);
            amountAOut = amountAOut - amountAOut * charge/10000;
        }

        require(amountAOut >= _amountAOutMin && amountBOut >= _amountBOutMin, "WQYUniSwap: price too low");

        if (_amountAIn > 0) {
            ERC20(tokenA).transferFrom(account, address(this), _amountAIn);
            ERC20(tokenB).transfer(account, amountBOut);
        } else {
            ERC20(tokenB).transferFrom(account, address(this), _amountBIn);
            ERC20(tokenA).transfer(account, amountAOut);
        }

        _updateReserves();
    }
    //更新
    function _updateReserves() private {
        reserveA = ERC20(tokenA).balanceOf(address(this));
        reserveB = ERC20(tokenB).balanceOf(address(this));
    }
}
