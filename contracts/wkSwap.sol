// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FT.sol";
import "./myERC20.sol";

@@ -65,21 +65,21 @@ contract Swap is myERC20{
        if (reserveA == 0 && reserveB == 0) {
            ERC20(TokenA).transferFrom(msg.sender, address(this), amountADesired);
            ERC20(TokenB).transferFrom(msg.sender, address(this), amountBDesired);
            mint(address(this));
            mint(to);
        } else {
            uint amountBOptimal = amountADesired * reserveB / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
                ERC20(TokenA).transferFrom(msg.sender, address(this), amountADesired);
                ERC20(TokenB).transferFrom(msg.sender, address(this), amountBOptimal);
                mint(address(this));
                mint(to);
            } else {
                uint amountAOptimal = amountBDesired * reserveA / reserveB;
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                ERC20(TokenA).transferFrom(msg.sender, address(this), amountAOptimal);
                ERC20(TokenB).transferFrom(msg.sender, address(this), amountBDesired);
                mint(address(this));
                mint(to);
            }
        }
    }
@@ -170,7 +170,7 @@ contract Swap is myERC20{
        amountA = liquidity * balanceA / _totalSupply; 
        amountB = liquidity * balanceB / _totalSupply; 
        require(amountA > 0 && amountB > 0, "INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _burn(to, liquidity);
        ERC20(TokenA).transfer(TokenA, amountA);
        ERC20(TokenB).transfer(TokenB, amountB);
    }
