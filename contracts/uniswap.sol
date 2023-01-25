// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FT.sol";

contract uniswap{
    address  tokenB;
    address  tokenA;
    uint256  k;
    
    uint  totalA;
    uint  totalB;
    address creater;
    
    constructor(address _tokenA,address _tokenB,address _creater){
         tokenA = _tokenA;
         tokenB = _tokenB;
        creater = _creater;
    }

    
    function update(uint256 valueA,uint256 valueB,int flag)private{
        if(flag == 0){
        totalA += valueA;
        totalB += valueB;
        }else{
        totalA -= valueA;
        totalB -= valueB;
        }
        k = totalA * totalB;
    }

     //换币 A-B
    function AtoB(uint256 valueA)public{
        require(ERC20(tokenA).allowance(msg.sender,address(this))>=valueA && ERC20(tokenA).balanceOf(msg.sender) >= valueA);
        (uint256 obtainB,uint256 fee) = slip(valueA,0);
        
        require(totalB >= obtainB);
        ERC20(tokenB).transfer(msg.sender,obtainB-fee);
        ERC20(tokenB).transfer(creater,fee);
        totalB -= obtainB;
        k = totalA * totalB;
    }
    // B-A
    function BtoA(uint256 valueB)public {
        require(ERC20(tokenB).allowance(msg.sender,address(this))>=valueB && ERC20(tokenB).balanceOf(msg.sender) >= valueB);
        (uint256 obtainA,uint256 fee) = slip(valueB,0);
     
        require(totalA >= obtainA);
        ERC20(tokenA).transfer(msg.sender,obtainA-fee);
        ERC20(tokenA).transfer(creater,fee);
        totalA -= obtainA;
        k = totalA * totalB;
    }
	

    // 增加流动性
    function Addliquidity(uint256 valueA,uint256 valueB)public  {
        require(ERC20(tokenA).balanceOf(msg.sender) >= valueA && ERC20(tokenB).balanceOf(msg.sender) >= valueB);
        uint256  rate;

        if(totalA == 0 || totalB == 0){
            ERC20(tokenA).transferFrom(msg.sender,address(this),valueA);
            ERC20(tokenB).transferFrom(msg.sender,address(this),valueB);
        }else if(totalA >= totalB){
            require(valueB != 0);
            rate = totalA / totalB;
            require(valueA/ valueB == rate);
            ERC20(tokenA).transferFrom(msg.sender,address(this),valueA);
            ERC20(tokenB).transferFrom(msg.sender,address(this),valueB);
        }else if(totalB >= totalA){
            require(valueA != 0);
            rate = totalB / totalA;
            require(valueB/ valueA == rate);
            ERC20(tokenA).transferFrom(msg.sender,address(this),valueA);
            ERC20(tokenB).transferFrom(msg.sender,address(this),valueB);
        }
        
        update(valueA,valueB,0);
    }

    // 移除流动性
    function Reducedliquidity (uint256 valueA,uint256 valueB)public {
        require(totalA >= valueA && valueB >= valueB);
        ERC20(tokenA).transfer(msg.sender,valueA);
        ERC20(tokenB).transfer(msg.sender,valueA);

        update(valueA,valueB,1);
    }

   


    // 滑点和手续费
    function slip(uint256 input, int flag)private  returns(uint256 obtain,uint256 value){
        if(flag == 0){
            totalA += input;
            obtain = totalB - k/totalA;
            return (obtain, obtain / 1000 * 3);
        }else{
            totalB += input;
            obtain = totalA - k/totalB;
            return (obtain,obtain / 1000 * 3);
        }
    }

   

}