// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FT.sol";

contract tokenPair {
    address public A;
    address public B;
    address setter;
    uint256 public amountA;
    uint256 public amountB;
    mapping(address => providInfo) public provider;

    uint256 k;

    uint256 private unlocked = 1;

    struct providInfo {
        uint256 A;
        uint256 B;
    }

    modifier lock() {
        require(unlocked == 1, "Uniswap: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(
        address tokenA,
        address tokenB,
        address set
    ) {
        A = tokenA;
        B = tokenB;
        setter = set;
    }

    // 更新状态
    function update(
        uint256 valueA,
        uint256 valueB,
        int256 flag
    ) private lock {
        if (flag == 0) {
            amountA += valueA;
            amountB += valueB;
        } else {
            amountA -= valueA;
            amountB -= valueB;
        }
        k = amountA * amountB;
    }

    // 当前兑换率
    function Rate() public view returns (uint256) {
        uint256 rate;
        if (amountA >= amountB) {
            require(amountB != 0, "err:value unclear");
            rate = (amountA * 100) / amountB;
            return rate;
        } else {
            require(amountA != 0, "err:value unclear");
            rate = (amountB * 100) / amountA;
        }
        return rate;
    }

    // 增加流动性
    function addMobility(uint256 valueA, uint256 valueB) public lock {
        require(
            ERC20(A).balanceOf(msg.sender) >= valueA &&
                ERC20(B).balanceOf(msg.sender) >= valueB,
            "err:value is not enough"
        );
        uint256 rate;

        if (amountA == 0 || amountB == 0) {
            ERC20(A).transferFrom(msg.sender, address(this), valueA);
            ERC20(B).transferFrom(msg.sender, address(this), valueB);
        } else if (amountA >= amountB) {
            require(valueB != 0, "err:valueB is zero");
            rate = (amountA * 100) / amountB;
            require((valueA * 100) / valueB == rate, "err:value is mismatch");
            ERC20(A).transferFrom(msg.sender, address(this), valueA);
            ERC20(B).transferFrom(msg.sender, address(this), valueB);
        } else if (amountB >= amountA) {
            require(valueA != 0, "err:valueA is zero");
            rate = (amountB * 100) / amountA;
            require((valueB * 100) / valueA == rate, "err:value is mismatch");
            ERC20(A).transferFrom(msg.sender, address(this), valueA);
            ERC20(B).transferFrom(msg.sender, address(this), valueB);
        }
        providInfo storage user = provider[msg.sender];
        user.A += valueA;
        user.B += valueB;

        update(valueA, valueB, 0);
    }

    // 移除流动性
    function subMobility(uint256 valueA, uint256 valueB) public lock {
        require(
            provider[msg.sender].A >= valueA &&
                provider[msg.sender].B >= valueB,
            "err:provide is not enough "
        );
        require(amountA >= valueA && valueB >= valueB, "amount is not enough");
        ERC20(A).transfer(msg.sender, valueA);
        ERC20(B).transfer(msg.sender, valueA);
        providInfo storage user = provider[msg.sender];
        user.A -= valueA;
        user.B -= valueB;
        update(valueA, valueB, 1);
    }

    // 滑点
    function slip(uint256 input, int256 flag) private returns (uint256 out) {
        if (flag == 0) {
            uint256 rate;
            if (amountA >= amountB) {
                rate = amountA / amountB;
                amountA += input;
                uint256 hope = input / rate;
                out = amountB - k / amountA;
                require(hope / (hope - out) >= 20, "err:loss is too great");

                return out;
            } else {
                rate = (amountB * 100) / amountA;
                amountA += input;
                uint256 hope = (input * rate) / 100;
                out = amountB - k / amountA;
                require(hope / (hope - out) >= 20, "err:loss is too great");
                return out;
            }
        } else {
            uint256 rate;
            if (amountA >= amountB) {
                rate = (amountA * 100) / amountB;
                amountB += input;
                out = amountA - k / amountB;
                uint256 hope = (input * rate) / 100;

                require(hope / (hope - out) >= 20, "err:loss is too great");

                return out;
            } else {
                rate = amountB / amountA;
                amountB += input;
                out = amountA - k / amountB;
                uint256 hope = input / rate;

                require(hope / (hope - out) >= 20, "err:loss is too great");
                return out;
            }
        }
    }

    // 交易手续费
    function charge(uint256 out) private pure returns (uint256) {
        return (out / 1000) * 3;
    }

    // 交易
    function AswapB(uint256 valueA) public lock {
        require(
            ERC20(A).allowance(msg.sender, address(this)) >= valueA &&
                ERC20(A).balanceOf(msg.sender) >= valueA
        );
        uint256 getB = slip(valueA, 0);
        uint256 fee = charge(getB);
        require(amountB >= getB, "err:amountB is not enough");
        ERC20(B).transfer(msg.sender, getB - fee);
        ERC20(B).transfer(setter, fee);
        amountB -= getB;
        k = amountA * amountB;
    }

    function BswapA(uint256 valueB) public lock {
        require(
            ERC20(B).allowance(msg.sender, address(this)) >= valueB &&
                ERC20(B).balanceOf(msg.sender) >= valueB
        );
        uint256 getA = slip(valueB, 1);
        uint256 fee = charge(getA);
        require(amountA >= getA, "err:amountA is not enough");
        ERC20(A).transfer(msg.sender, getA - fee);
        ERC20(A).transfer(setter, fee);
        amountA -= getA;
        k = amountA * amountB;
    }
}
