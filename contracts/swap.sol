// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FT.sol";

contract uniswap{

    address public coin_A;//coin_A地址
    address public coin_B;//coin_B地址
    uint public amount_A;//coin_A的储备量
    uint public amount_B;//coin_B的储备量
    address creater;
    mapping(address=>storInfo) public userstor;
    uint256 k;
    uint private unlocked = 1;

    struct storInfo{
        uint256 coin_A;
        uint256 coin_B;
    }

    constructor(address tokenA,address tokenB,address set){
        coin_A = tokenA;
        coin_B = tokenB;
        creater = set;
    }

     modifier lock() {
        require(unlocked == 1, 'Uniswap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function update(uint256 valueA,uint256 valueB,int flag)private{
        if(flag == 0){
        amount_A += valueA;
        amount_B += valueB;
        }else{
        amount_A -= valueA;
        amount_B -= valueB;
        }
        k = amount_A * amount_B;
    }


    function Rate()public view returns(uint256){
        uint256 rate;
        if(amount_A >= amount_B){
            require(amount_B != 0);
            rate = amount_A*100 / amount_B;
            return rate;
        }else{
            require(amount_A != 0);
            rate = amount_B*100 / amount_A;
        }
        return rate;
    }

   // 添加流动性
    function addLiquidity(uint256 valueA,uint256 valueB)public lock {
        require(valueA != 0 && valueB != 0);
        require(ERC20(coin_A).balanceOf(msg.sender) >= valueA && ERC20(coin_B).balanceOf(msg.sender) >= valueB,"token is not enough");
       
        storInfo storage user = userstor[msg.sender];
        user.coin_A += valueA;
        user.coin_B += valueB; 

        ERC20(coin_A).transferFrom(msg.sender,address(this),valueA);
        ERC20(coin_B).transferFrom(msg.sender,address(this),valueB);
       
        
    
        update(valueA,valueB,0);
    }

    // 移除流动性
    function removeLiquidity(uint256 valueA,uint256 valueB)public lock {
        require(userstor[msg.sender].coin_A >= valueA && userstor[msg.sender].coin_B >= valueB);
        require(amount_A >= valueA && valueB >= valueB);
        ERC20(coin_A).transfer(msg.sender,valueA);
        ERC20(coin_B).transfer(msg.sender,valueA);
        storInfo storage user = userstor[msg.sender];
        user.coin_A -= valueA;
        user.coin_B -= valueB; 
        update(valueA,valueB,1);
    }

    function charge(uint256 out)pure private returns(uint256){
        return out / 1000 * 3;
    }

    //实现交易功能+滑点+手续费
    function swap1(uint256 valueA)public lock{
        require(ERC20(coin_A).allowance(msg.sender,address(this))>=valueA && ERC20(coin_A).balanceOf(msg.sender) >= valueA);
        // 滑点
        uint256 rate = Rate();
        uint256 ev;
        if(amount_A >= amount_B){
            ev = valueA / rate *100;
        }else{
            ev = valueA * rate /100;
        }
        amount_A += valueA;
        uint256 getB = amount_B - k/amount_A;
        require(ev / (ev - getB) >= 20);
        // 计算手续费
        uint256 fee = charge(getB);
        require(amount_B >= getB,"amount_B is not enough");
        ERC20(coin_B).transfer(msg.sender,getB-fee);
        ERC20(coin_B).transfer(creater,fee);
        amount_B -= getB;
        k = amount_A * amount_B;
    }

    function swap2(uint256 valueB)public lock{
        require(ERC20(coin_B).allowance(msg.sender,address(this))>=valueB && ERC20(coin_B).balanceOf(msg.sender) >= valueB);
        // 滑点
        uint256 rate = Rate();
        uint256 ev;
        if(amount_B >= amount_A){
            ev = valueB / rate *100;
        }else{
            ev = valueB * rate /100;
        }
        amount_B += valueB;
        uint256 getA = amount_A - k/amount_B;
        require(ev / (ev - getA) >= 20);

        uint256 fee = charge(getA);
        
        require(amount_A >= getA,"amount_A is not enough");
        ERC20(coin_A).transfer(msg.sender,getA-fee);
        ERC20(coin_A).transfer(creater,fee);
        amount_A -= getA;
        k = amount_A * amount_B;
    }

}