// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenExchange is ERC20 {
    using SafeMath for uint256;

    ERC20 public immutable tokenA;
    ERC20 public immutable tokenB;

    event InitPool(address provider, uint amountA, uint amountB, uint amountLP);
    event AddLiquidity(address provider, uint amountA, uint amountB, uint amountLP);
    event RemoveLiquidity(address provider, address to, uint amountA, uint amountB);
    event SwapAtoB(address trader, uint soldToken, uint buyToken);
    event SwapBtoA(address trader, uint soldToken, uint buyToken);


    constructor(ERC20 _tokenA, ERC20 _tokenB) ERC20("Volar", "V") {
        require(address(_tokenA) != address(0) && address(_tokenB) != address(0), "Address can't be zero");
        require(address(_tokenA) != address(_tokenB), "The address must be different");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function _calculateLiquidity(uint _soldToken, bool flag) private view returns(uint) {
        //true为输入A计算B，false为输入B计算A
        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));
        if(flag) {
            return _soldToken.mul(balanceB).div(balanceA);
        } else {
            return _soldToken.mul(balanceA).div(balanceB);
        }
    }

    function firstAddLiquidity(uint _tokenA, uint _tokenB) external returns (uint amountLP) {
        require(totalSupply() == 0, "The pool exist");
        tokenA.transferFrom(msg.sender, address(this), _tokenA);
        tokenB.transferFrom(msg.sender, address(this), _tokenB);
        uint _amount = Math.sqrt(_tokenA.mul(_tokenB));
        _mint(msg.sender, _amount);      
        emit InitPool(msg.sender, _tokenA, _tokenB, _amount);
        return _amount;
    }

    function addLiquidityA(uint _tokenA) external returns (uint amountLP) {
        uint _total = totalSupply();
        require(_total != 0, "The pool does not exist");
        uint _tokenB = _calculateLiquidity(_tokenA, true);
        uint _reserveA = tokenA.balanceOf(address(this));
        tokenA.transferFrom(msg.sender, address(this), _tokenA);
        tokenB.transferFrom(msg.sender, address(this), _tokenB);       
        uint _amount = _tokenA.mul(_total).div(_reserveA);
        _mint(msg.sender, _amount);
        emit AddLiquidity(msg.sender, _tokenA, _tokenB, _amount);
        return _amount;
    }

    function addLiquidityB(uint _tokenB) external returns (uint amountLP) {
        uint _total = totalSupply();
        require(_total != 0, "The pool does not exist");
        uint _tokenA = _calculateLiquidity(_tokenB, false);
        uint _reserveB = tokenB.balanceOf(address(this));
        tokenA.transferFrom(msg.sender, address(this), _tokenA);
        tokenB.transferFrom(msg.sender, address(this), _tokenB);
        uint _amount = _tokenB.mul(_total).div(_reserveB);
        _mint(msg.sender, _amount);
        emit AddLiquidity(msg.sender, _tokenA, _tokenB, _amount);
        return _amount;
    }

    function removeLiquidity(address _to) external returns (uint amountA, uint amountB) {
        uint _lpToken = balanceOf(msg.sender);
        uint _total = totalSupply();
        require(_lpToken != 0, "You are not provider");
        uint _balanceA = tokenA.balanceOf(address(this));
        uint _balanceB = tokenB.balanceOf(address(this));
        uint _amountA = _lpToken.mul(_balanceA).div(_total);
        uint _amountB = _lpToken.mul(_balanceB).div(_total);
        _burn(msg.sender, _lpToken);
        tokenA.transfer(_to, _amountA);
        tokenA.transfer(_to, _amountB);
        emit RemoveLiquidity(msg.sender, _to, _amountA, _amountB);
        return (_amountA, amountB);
    }

    function getInputPrice(uint _boughtToken, bool flag) public view returns(uint inputPrice) {
        //true为卖A换B，false为卖B换A
        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));
        if(flag) {
            uint _numerator = _boughtToken.mul(1000).mul(balanceA);
            uint _denominator = balanceB.sub(_boughtToken).mul(997);
            return _numerator.div(_denominator);
        } else {
            uint _numerator = _boughtToken.mul(1000).mul(balanceB);
            uint _denominator = balanceA.sub(_boughtToken).mul(997);
            return _numerator.div(_denominator);
        }
    }

    function getOutputprice(uint _soldToken, bool flag) public view returns(uint outPrice) {
        //true为卖A换B，false为卖B换A
        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));
        if(flag) {
            uint _numerator = _soldToken.mul(997).mul(balanceB);
            uint _denominator = balanceA.mul(1000).add(_soldToken.mul(997));
            return _numerator.div(_denominator);
        } else {
            uint _numerator = _soldToken.mul(997).mul(balanceA);
            uint _denominator = balanceB.mul(1000).add(_soldToken.mul(997));
            return _numerator.div(_denominator);
        }
    } 

    function AExchangeB(uint _tokenA, uint _expectToken, uint _ratioNumerator, uint _ratioDenominator) external returns(uint amountB) {
        uint _amountB = getOutputprice(_tokenA, true);
        tokenA.transferFrom(msg.sender, address(this), _tokenA);
        require(!_slippage(_tokenA, _amountB, _expectToken, _ratioNumerator, _ratioDenominator), "The price has changed");
        tokenB.transfer(msg.sender, _amountB);
        emit SwapAtoB(msg.sender, _tokenA, _amountB);
        return _amountB;
    }

    function BExchangeA(uint _tokenB, uint _expectToken, uint _ratioNumerator, uint _ratioDenominator) external returns(uint amountA) {
        uint _amountA = getOutputprice(_tokenB, false);
        tokenB.transferFrom(msg.sender, address(this), _tokenB);
        require(!_slippage(_amountA, _tokenB, _expectToken, _ratioNumerator, _ratioDenominator), "The price has changed");
        tokenA.transfer(msg.sender, _amountA);
        emit SwapBtoA(msg.sender, _tokenB, _amountA);
        return _amountA;
    }

    function _slippage(uint _realA, uint _realB, uint _expectToken, uint _ratioNumerator, uint _ratioDenominator) private view returns(bool) {
        //true是AtoB, false是BtoA
        uint _realAmount = getOutputprice(_realA, true);
        if(_realAmount == _realB) {
            if(_realB >= _expectToken) {
                return false;
            }
            uint _numerator = _expectToken.sub(_realB).mul(_ratioDenominator);
            uint _denominator = _realB.mul(_ratioNumerator);
            if(_numerator.div(_denominator) < 1) {
                return true;
            }
        } else {
            if(_realA >= _expectToken) {
                return false;
            }
            uint _numerator = _expectToken.sub(_realA).mul(_ratioDenominator);
            uint _denominator = _realA.mul(_ratioNumerator);
            if(_numerator.div(_denominator) < 1) {
                return true;
            }
        }
        return false;
    }

    function getReseveA() external view returns(uint) {
        return tokenA.balanceOf(address(this));
    }

    function getReseveB() external view returns(uint) {
        return tokenB.balanceOf(address(this));
    }
}