// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FT.sol";

contract SwapPair is FT {
    address public token0;
    address public token1;

    address public factory;

    uint256 public reserve0;
    uint256 public reserve1;

    uint8 public fee; 
    bool public initialized = false;

    constructor(address _token0, address _token1) FT("LPTokens", "LP") {
        token0 = _token0;
        token1 = _token1;
        factory = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "SSQSwap: only factory!");
        _;
    }

    function sync(address account) external onlyFactory {
        _updateReserves();
        super._mint(account, reserve0 * reserve1);
    }

    function addLiquidity(uint256 count) external {
        address account = msg.sender;
        uint256 currentLPTotalSupply = totalSupply();
        require currentLPTotalSupply > 0;

        uint256 _token0Count = reserve0 * count / currentLPTotalSupply;
        uint256 _token1Count = reserve1 * count / currentLPTotalSupply;

        ERC20(token0).transferFrom(account, address(this), _token0Count);
        ERC20(token1).transferFrom(account, address(this), _token1Count);

        super._mint(account, count);

        _updateReserves();
    }

    function removeLiquidity(uint256 count) external {
        address account = msg.sender;

        uint256 currentLPTotalSupply = totalSupply();
        require currentLPTotalSupply > count;
        require balanceOf(account) >= count;

        uint256 _token0Count = reserve0 * count / currentLPTotalSupply;
        uint256 _token1Count = reserve1 * count / currentLPTotalSupply;

        super._burn(account, count);

        ERC20(token0).transfer(account, _token0Count);
        ERC20(token1).transfer(account, _token1Count);

        _updateReserves();
    }

    function swap(uint256 _amount0In, uint256 _amount1In, uint256 _amount0OutMin, uint256 _amount1OutMin) external {
        address account = msg.sender;

        (uint256 amount0Out, uint256 amount1Out) = getAmountOut(_amount0In, _amount1In);
        require(amount0Out >= _amount0OutMin && amount1Out >= _amount1OutMin, "SSQSwap: price too low");

        if (_amount0In > 0) {
            ERC20(token0).transferFrom(account, address(this), _amount0In);
            ERC20(token1).transfer(account, amount1Out);
        } else {
            ERC20(token1).transferFrom(account, address(this), _amount1In);
            ERC20(token0).transfer(account, amount0Out);
        }

        _updateReserves();
    }

    function getAmountOut(uint256 _amount0In, uint256 _amount1In) public view returns(uint256 amount0Out, uint256 amount1Out){
            if(_amount0In > 0) {
                amount1Out = reserve1 - reserve0 * reserve1 / (reserve0 + _amount0In);
                amount1Out = amount1Out - amount1Out * fee/10000;
            } else {
                amount0Out = reserve0 - reserve0 * reserve1 / (reserve1 + _amount1In);
                amount0Out = amount0Out - amount0Out * fee/10000;
            }
    }

    function _updateReserves() private {
        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));
    }
}
