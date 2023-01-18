// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract mytest {
    //A代表稀有货币
    mapping(address => uint256) public balanceOfA;
    //B代表通用货币
    mapping(address => uint256) public balanceOfB;
    uint256 totalA = 0;
    uint256 totalB = 0;
    uint256 public k = 0;
    address server = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

    //初始化账户中代币A和代币B的值
    function mint(address usr, uint256 acountA, uint256 acountB) public {
        balanceOfA[usr] = acountA;
        balanceOfB[usr] = acountB;
        totalA = totalA + acountA;
        totalB = totalB + acountB;
        k = totalA * totalB;
    }

    //新增A和B的值
    function add(address usr, uint256 acountA, uint256 acountB) public {
        balanceOfA[usr] = balanceOfA[usr] + acountA;
        balanceOfB[usr] = balanceOfB[usr] + acountB;
        totalA = totalA + acountA;
        totalB = totalB + acountB;
        k = totalA * totalB;
    }

    //投入A换B
    function AexchangeB(address usr, uint256 acount) public returns(uint256){
        uint256 flag = totalB;
        balanceOfA[usr] = balanceOfA[usr] + acount;
        totalA = totalA + acount;
        totalB = k / totalA;
        balanceOfB[usr] = balanceOfB[usr] - (flag - totalB);
        return flag - totalB;
    }

    //投入B换A
    function BexchangeA(address usr, uint256 acount) public returns(uint256){
        uint256 flag = totalA;
        balanceOfB[usr] = balanceOfB[usr] + acount;
        totalB = totalB + acount;
        totalA = k / totalB;
        balanceOfA[usr] = balanceOfA[usr] - (flag - totalA);
        return flag - totalA;
    }

    //A交易B
    function AtransferB(address from, address to, uint256 acount) public returns(uint256){
        require(balanceOfA[from] >= acount);
        uint256 price = totalB / totalA;
        balanceOfA[from] = balanceOfA[from] - acount;
        balanceOfA[to] = balanceOfA[to] + acount;
        balanceOfB[from] = balanceOfB[from] + acount * price;
        balanceOfB[to] = balanceOfB[to] - acount * price;
        transactionfee(to,price,acount);
        return acount * price;
    }

    //B交易A
    function BtransferA(address from, address to, uint256 acount) public returns(uint256){
        require(balanceOfB[from] >= acount);
        uint256 price = totalA / totalB;
        balanceOfB[from] = balanceOfB[from] - acount;
        balanceOfB[to] = balanceOfB[to] + acount;
        balanceOfA[from] = balanceOfA[from] + acount * price;
        balanceOfA[to] = balanceOfA[to] - acount * price;
        transactionfee(to,price,1);
        return acount * price;
    }

    //交易手续费
    function transactionfee(address to, uint256 price, uint256 acount) public {
        if(price > 1){
            balanceOfA[to] = balanceOfA[to] - acount;
            balanceOfA[server] = balanceOfA[server] + acount;
        }else{
            balanceOfB[to] = balanceOfB[to] - acount;
            balanceOfB[server] = balanceOfB[server] + acount;
        }
    }







    

}
