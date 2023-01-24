//计算函数提供合约
pragma solidity ^0.8.10;
contract Math {
   

    function sqr(uint256 b) internal  returns (uint256 c) {
        if (b > 3) {
            c = b;
            uint256 a = b / 2 + 1;
            while (a < c) {
                c = a;
                a = (b / a + a) / 2;
            }
        } else if (b != 0) {
            c = 1;
        }
    }
  function minVar(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c=(a-b)>0?b:a;
    }

}
