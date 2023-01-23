// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Swap is Ownable {
    using SafeMath for uint256;

    // ERC20规范定义的变量
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 实现手续费功能，千分之三手续费
    uint256 public fee = 3;

    // 实现滑点功能
    uint256 public slippage;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // 增加流动性
    function mint(address account, uint256 amount) public onlyOwner {
        require(amount > 0, "Cannot mint zero or negative tokens.");
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    // 移出流动性
    function burn(address account, uint256 amount) public onlyOwner {
        require(balanceOf[account] >= amount, "Not enough balance.");
        balanceOf[account] = balanceOf[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    // 交易功能
    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value.mul(1000).div(1000 + fee), "Not enough balance.");
        require(balanceOf[to] + value <= balanceOf[to].add(value).mul(1000 + slippage).div(1000), "Exceeds slippage rate.");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value.mul(1000).div(1000 + fee));
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
    }
}
