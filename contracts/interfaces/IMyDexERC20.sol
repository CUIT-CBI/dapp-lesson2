pragma solidity >=0.5.0;

//ERC20接口合约，规定了需要实现的所有ERC20标准方法。

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);     //授权事件；
    event Transfer(address indexed from, address indexed to, uint value);       //转账事件；

    function name() external pure returns (string memory);      //token的名字；
    function symbol() external pure returns (string memory);        //token的标志；
    function decimals() external pure returns (uint8);      //token的精度；

    function totalSupply() external view returns (uint);        //当前token的总供应量；
    function balanceOf(address owner) external view returns (uint);     //查询当前地址的余额；
    function allowance(address owner, address spender) external view returns (uint);        //查询owner允许spender交易的token数量；
    function approve(address spender, uint value) external returns (bool);      //token的拥有者向spender授权交易指定value数量的token；
    function transfer(address to, uint value) external returns (bool);      //交易；
    function transferFrom(address from, address to, uint value) external returns (bool);        //授权交易；

    function DOMAIN_SEPARATOR() external view returns (bytes32);        //返回[EIP712]所规定的DOMAIN_SEPARATOR值；
    function PERMIT_TYPEHASH() external pure returns (bytes32);        //返回[EIP2612]所规定的链下信息加密的类型；
    function nonces(address owner) external view returns (uint);        //返回EIP2612所规定每次授权的信息中所携带的nonce值是多少，防止授权过程遭到重放攻击。

    function permit(
        address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s
        ) external;     //EIP2612进行授权交易的方法，用来实现无gas(token的使用者不需要出gas)的token交易；
}
