// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Math{
    function sqrt(uint256 num1) public pure returns(uint256){
        require(num1 >= 0,'INVALID_DATA');
        uint256 x = (num1 + 1) / 2;
        uint256 y = num1;
        while(x < y){
            y = x;
            x = ( num1 / x + x) / 2;
        }
        assert(num1 / y == y);
        return y;
    }

    

    function mul(uint256 a,uint256 b) public pure returns(uint256){
      if(a == 0){
          return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
      return c;
    }

    function add(uint256 a, uint256 b) public pure returns(uint256){
      
        uint256 c = a + b;
        assert(c - a == b);
        return c;
    }

    function sub(uint256 a ,uint256 b) public pure returns(uint256){
        if (b ==0){
            return a;
        }
        uint256 c = a - b;
        assert(a - c == b);
        return c;
    }

    function div(uint256 a,uint256 b) public pure returns(uint256){
        require(b != 0,"INVALID_OPERATION");
        uint256 c = a / b;
        assert(c * b == a);
        return c;
    }

    function updiv(uint256 a,uint256 b) public pure returns(uint256){
        require ( b != 0,'INVALID_OPERATION');
        uint256 c = (a + b -1) / b;
        return c;
    }

    function quote(uint256 x,uint256 y,uint256 z) public pure returns(uint256){
        uint256 c = x * z / y;
        return c;
    }
}
