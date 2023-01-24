pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FT is ERC20, Pausable, Ownable{
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
    //映射存在交易对的地址
    mapping(address => bool) pairs;

    modifier OnlyPair(){
        require(pairs[msg.sender] == true);
        _;
    }
    //设置交易对提供者
    function setPair(address pair) public {
        pairs[pair] = true;
    }
    
    function mint(address account, uint256 amount) external OnlyPair {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

}
