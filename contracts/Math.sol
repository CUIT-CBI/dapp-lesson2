// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
contract Math {
     function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if(x<y){
           z=x;
        }else{
           z=y;
        }
    }
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
}
