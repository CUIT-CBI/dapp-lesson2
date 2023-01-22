// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './utils/Math.sol';

contract SwapERC20  {
    
    using Math for uint;

    //定义了ERC20代币的三个对外状态变量，名称，符号，精度
    string public constant name = 'Hyh token';
    string public constant symbol = 'HYH';
    uint8 public constant decimals = 18;
    
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    //追踪事件
    event Transfer(address indexed from, address indexed to, uint value);

 
    //进行代币增发
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    //进行代币销毁
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    
  

   
}
