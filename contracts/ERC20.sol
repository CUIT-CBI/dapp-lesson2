// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract ERC20 {
    string symbol;
    string name;
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    address public owner;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        mint(msg.sender, 100000000000000000000);
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'permission denied');
        _;
    }

    function mint(address to, uint value) public onlyOwner {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function burn(address from, uint value) external {
        require(from == msg.sender, 'permission denied');
        balanceOf[from] -= value;
        totalSupply += value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address from, address spender, uint value) private {
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

     function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, 'permission denied');
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
}
