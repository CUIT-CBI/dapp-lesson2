// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FT.sol";

contract TokenCreat {
    address public ads1;
    address public ads2;
    uint256 public index1;
    uint256 public index2;
    address setter;
    mapping(address => val) public provider;
    uint256 k;

    struct val {
        uint256 A;
        uint256 B;
    }

    constructor(address tokenA, address tokenB, address set) {
        ads1 = tokenA;
        ads2 = tokenB;
        setter = set;
    }

    modifier lock() {
        uint256 unlocked = 1;
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // 更新状态
    function update(uint256 valA, uint256 valB, int256 flag) private lock {
        if (flag == 0) {
            index1 += valA;
            index2 += valB;
        } else {
            index1 -= valA;
            index2 -= valB;
        }
        k = index1 * index2;
    }

    // 当前兑换率
    function Rate() public view returns (uint256) {
        uint256 rate;
        if (index1 >= index2) {
            require(index2 != 0, "value unclear");
            rate = (index1 * 100) / index2;
            return rate;
        } else {
            require(index1 != 0, "value unclear");
            rate = (index2 * 100) / index1;
        }
        return rate;
    }

    // 增加流动性
    function addMobility(uint256 valA, uint256 valB) public lock {
        require(
            ERC20(ads1).balanceOf(msg.sender) >= valA &&
                ERC20(ads2).balanceOf(msg.sender) >= valB,
            "value not enough"
        );
        uint256 rate;

        if (index1 == 0 || index2 == 0) {
            ERC20(ads1).transferFrom(msg.sender, address(this), valA);
            ERC20(ads2).transferFrom(msg.sender, address(this), valB);
        } else if (index1 >= index2) {
            require(valB != 0, "valB is zero");
            rate = (index1 * 100) / index2;
            require((valA * 100) / valB == rate, "value is mismatch");
            ERC20(ads1).transferFrom(msg.sender, address(this), valA);
            ERC20(ads2).transferFrom(msg.sender, address(this), valB);
        } else if (index1 >= index2) {
            require(valA != 0, "valA is zero");
            rate = (index2 * 100) / index1;
            require((valB * 100) / valA == rate, "value is mismatch");
            ERC20(ads1).transferFrom(msg.sender, address(this), valA);
            ERC20(ads2).transferFrom(msg.sender, address(this), valB);
        }
        val storage user = provider[msg.sender];
        user.A += valA;
        user.B += valB;

        update(valA, valB, 0);
    }

    // 移除流动性
    function remMobility(uint256 valA, uint256 valB) public lock {
        require(
            provider[msg.sender].A >= valA && provider[msg.sender].B >= valB,
            "provide  not enough"
        );
        require(index1 >= valA && valB >= valB, "not enough");
        ERC20(ads1).transfer(msg.sender, valA);
        ERC20(ads2).transfer(msg.sender, valA);
        val storage user = provider[msg.sender];
        user.A -= valA;
        user.B -= valB;
        update(valA, valB, 1);
    }

    // 滑点
    function slip(uint256 input, int256 flag) private returns (uint256 out) {
        if (flag == 0) {
            uint256 rate;
            if (index1 >= index2) {
                rate = index1 / index2;
                index1 += input;
                uint256 hope = input / rate;
                out = index2 - k / index1;
                require(hope / (hope - out) >= 20, "loss  too great");

                return out;
            } else {
                rate = (index1 * 100) / index2;
                index1 += input;
                uint256 hope = (input * rate) / 100;
                out = index2 - k / index1;
                require(hope / (hope - out) >= 20, "loss  too great");
                return out;
            }
        } else {
            uint256 rate;
            if (index1 >= index2) {
                rate = (index1 * 100) / index2;
                index2 += input;
                out = index1 - k / index2;
                uint256 hope = (input * rate) / 100;

                require(hope / (hope - out) >= 20, "loss too great");

                return out;
            } else {
                rate = index2 / index1;
                index2 += input;
                out = index1 - k / index2;
                uint256 hope = input / rate;

                require(hope / (hope - out) >= 20, "loss too great");
                return out;
            }
        }
    }

    // 交易手续费
    function charge(uint256 out) private pure returns (uint256) {
        return (out / 1000) * 3;
    }

    // 交易
    function AtoB(uint256 valA) public lock {
        require(
            ERC20(ads1).allowance(msg.sender, address(this)) >= valA &&
                ERC20(ads2).balanceOf(msg.sender) >= valA
        );
        uint256 getB = slip(valA, 0);
        uint256 fee = charge(getB);
        require(index2 >= getB, "not enough");
        ERC20(ads2).transfer(msg.sender, getB - fee);
        ERC20(ads2).transfer(setter, fee);
        index2 -= getB;
        k = index1 * index2;
    }

    function BtoA(uint256 valueB) public lock {
        require(
            ERC20(ads2).allowance(msg.sender, address(this)) >= valueB &&
                ERC20(ads2).balanceOf(msg.sender) >= valueB
        );
        uint256 getA = slip(valueB, 1);
        uint256 fee = charge(getA);
        require(index1 >= getA, "not enough");
        ERC20(ads1).transfer(msg.sender, getA - fee);
        ERC20(ads1).transfer(setter, fee);
        index1 -= getA;
        k = index1 * index2;
    }
}
