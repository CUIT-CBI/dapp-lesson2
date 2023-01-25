// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FT.sol";


library Math {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }


    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >b){
            return b;
        }else{
            return a;
        }
    }
}

contract SJZ is FT{
    uint public MINIMUM_LIQUIDITY = 10**3;

    address public token1;
    address public token2;
    uint112 public reserve1;
    uint112 public reserve2;

    constructor(address _token1, address _token2) FT("SJZtoken","SJZ") {
        token1 = _token1;
        token2 = _token2;
    }

    function getAmount(uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut) private pure returns (uint256 amountOut) {
        amountOut = (reserveIn * reserveOut) / (reserveIn + amountIn);
        return amountOut;
    }
    
    function getReserves() public view returns (uint112 _reserve1, uint112 _reserve2) {
        _reserve1 = reserve1;
        _reserve2 = reserve2;
    }

    function addLiquidity(uint amount1, uint amount2, address to) external returns(uint liquid) {
       require(to != token1 && to != token2, 'to ia wrong');
       (uint112 _reserve1, uint112 _reserve2) = getReserves();

       ERC20(token1).transferFrom(msg.sender,address(this),amount1);
       ERC20(token2).transferFrom(msg.sender,address(this),amount2);

       uint256 currentSupply = super.totalSupply();
       uint256 reserveAfter1 = _reserve1 + amount1;
       uint256 reserveAfter2 = _reserve2 + amount2;

       if(currentSupply == 0 ){
           liquid = Math.sqrt(amount1 * amount2) - MINIMUM_LIQUIDITY;
           _mint(msg.sender,liquid);
       }else{
           liquid = Math.min(
               reserveAfter1 * currentSupply / _reserve1,
               reserveAfter2 * currentSupply / _reserve2
               );
        }
        super._mint(to,liquid);
        reserve1 = uint112(reserveAfter1);
        reserve2 = uint112(reserveAfter2);
    }

    function removeLiquidity(uint liquid) public returns(uint amount1, uint amount2) {
        (uint112 _reserve1, uint112 _reserve2) = getReserves();

        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint balance2 = ERC20(token2).balanceOf(address(this));
        transfer(address(this),liquid);
        uint currentSupply = super.totalSupply();

        amount1 = liquid * _reserve1 / currentSupply;
        amount2 = liquid * _reserve2 / currentSupply;
        super._burn(msg.sender,liquid);

        ERC20(token1).transfer(msg.sender,amount1);
        ERC20(token2).transfer(msg.sender,amount2);

        balance1 = ERC20(token1).balanceOf(address(this));
        balance2 = ERC20(token2).balanceOf(address(this));

        reserve1 = uint112(balance1);
        reserve2 = uint112(balance2);
    }
    
    function trade(
        uint Inamount1, uint Inamount2, uint Minamount,
        address fromToken, address toToken, address to) external{
            require(to != fromToken && to != toToken);
            (uint112 _reserve1, uint112 _reserve2) = getReserves();

            if(Inamount1 > 0) ERC20(fromToken).transferFrom(msg.sender, address(this), Inamount1);
            if(Inamount2 > 0) ERC20(fromToken).transferFrom(msg.sender, address(this), Inamount2);

            uint balance1 = ERC20(token1).balanceOf(address(this));
            uint balance2 = ERC20(token2).balanceOf(address(this));

            uint Outamount1 = getAmount(Inamount1,_reserve1,_reserve2) * 997 /1000;
            uint Outamount2 = getAmount(Inamount2,_reserve2,_reserve1) * 997 /1000;

            if(Outamount1 > 0) {
                require(Outamount1 >= Minamount);
                ERC20(toToken).transferFrom(msg.sender,to,Outamount1);
            }
            
            if(Outamount2 > 0) {
                require(Outamount2 >= Minamount);
                ERC20(toToken).transferFrom(msg.sender,to,Outamount1);
            }
            
            reserve1 = uint112(balance1);
            reserve2 = uint112(balance2);
        }

}

    
