pragma solidity =0.5.16;

//本代码主要参考uniswap V2 core的UQ112x112相关代码。
//UQ112x112的功能是模拟浮点数。整数部分和小数部分分别占112位。

// 范围: [0, 2**112 - 1]
// 分辨率: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; 
    }

    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
