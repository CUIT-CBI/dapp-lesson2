// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FT.sol";
 
 // 参考地址https://github1s.com/finndayton/DEX/blob/HEAD/contracts/exchange.sol
contract Ztoken is IERC20 {
    using SafeMath for uint;

    string public constant symbol = 'ZYX';             
    string public constant name = 'ZYXCoin';          
    uint8 public constant decimals = 18;
    uint public _totalSupply;//该币的总额
    address public admin;
    bool private minting = true;
    mapping(address => uint) balances;//账户余额
    mapping(address => mapping(address => uint)) allowed;//授权金额
    
    event Mint(string message, uint data);


    constructor() {
        _totalSupply = 0;
        balances[msg.sender] = 0;  
        admin = msg.sender;                
    }

    //铸币权限检查
    modifier AdminOnly {
        require(msg.sender == admin);
        _;
    }

    //铸币权限检查
    modifier MintingEnabled {
        require(minting, "Minting has been disabled");
        _; 
    }

    //铸币
    function _mint(uint amount) 
        public 
        AdminOnly
        MintingEnabled
    {
        _totalSupply = _totalSupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit Mint("Number of coins this time: ", amount);
    }

    //收回铸币权限
    function _disable_mint()
        public
        AdminOnly
    {
        minting = false;
    }
    
    //查看当前货币总量
    function totalSupply() 
        public 
        override
        view 
        returns (uint) 
    {
        return _totalSupply;
    }
 
    //查看指定用户余额
    function balanceOf(address account) 
        public
        override 
        view 
        returns (uint) 
    {
        return balances[account];
    }
 
    //转账：本账户->指定账户
    function transfer(address receiver, uint amount) 
        public
        override 
        returns (bool) 
    {
        require(balances[msg.sender] >= amount, "Your balance is insufficient");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }
 
    //授权：本账户->指定账户
    function approve(address receiver, uint amount) 
        public 
        override 
        returns (bool) 
    {
        allowed[msg.sender][receiver] = amount;
        emit Approval(msg.sender, receiver, amount);
        return true;
    }

    //查询owner地址授权给delegate地址多少货币
    function allowance(address owner, address delegate) 
        public
        override 
        view 
        returns (uint) 
    {
        return allowed[owner][delegate];
    }
 
    //转账：指定地址->指定地址
    function transferFrom(address owner, address buyer, uint numTokens) 
        public
        override 
        returns (bool) 
    {
        require(balances[owner] >= numTokens);
        require(allowed[owner][msg.sender] >= numTokens);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}