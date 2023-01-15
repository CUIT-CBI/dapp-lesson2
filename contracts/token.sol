// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FT.sol";
 
contract WuChang is IERC20 {
    using SafeMath for uint;
    //将库函数SafeMath附加到uint类型
    string public constant symbol = 'WC';             
    string public constant name = 'WuChang';          
    uint8 public constant decimals = 18;
    uint public _totalSupply;
    address public admin;
    bool private minting = true;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowence;


    constructor() {
        _totalSupply = 0;
        balances[msg.sender] = 0;  
        admin = msg.sender;                
    }

    //铸币权限检查 保证铸币人只能是admin
    modifier OnlyAdmin {
        require(msg.sender == admin);
        _;
    }

    //铸币权限检查
    modifier MintingEnabled {
        require(minting, "Minting has been disabled!");
        _; 
    }

    //铸币
    function _mint(uint amount) 
        public 
        OnlyAdmin
        MintingEnabled
    {
        _totalSupply = _totalSupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
    }

    //收回铸币权限
    function _disableMint()
        public
        OnlyAdmin
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
 
    //从本账户转账到指定账户
    function transfer(address recipient, uint amount) 
        public
        override 
        returns (bool) 
    {
        require(balances[msg.sender] >= amount, "Your balance is not enough!");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
 
    //从本账户授予权限到指定账户
    function approve(address recipient, uint amount) 
        public 
        override 
        returns (bool) 
    {
        allowence[msg.sender][recipient] = amount;
        emit Approval(msg.sender, recipient, amount);
        return true;
    }

    //查询owner地址授权给delegate地址多少货币
    function allowance(address owner, address delegate) 
        public
        override 
        view 
        returns (uint) 
    {
        return allowence[owner][delegate];
    }
 
    //从指定地址转账到指定地址
    function transferFrom(address owner, address buyer, uint amount) 
        public
        override 
        returns (bool) 
    {
        require(balances[owner] >= amount,"Your balance is not enough!");
        require(allowence[owner][msg.sender] >= amount,"Your allowence from owner is not enough!");
        balances[owner] = balances[owner].sub(amount);
        allowence[owner][msg.sender] = allowence[owner][msg.sender].sub(amount);
        balances[buyer] = balances[buyer].add(amount);
        emit Transfer(owner, buyer, amount);
        return true;
    }
}