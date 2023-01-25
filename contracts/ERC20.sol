pragma solidity =0.5.16;

import 'ERC20.sol';
import 'SafeMath.sol';

contract ERC20 is IERC20 {
	using SafeMath for uint;
	string public constant name = ' _ERC20';
	uint  public totalSupply;
	mapping(address => uint) public balanceOf;
	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
	
	constructor() public {
		uint chainId;
		 DOMAIN_SEPARATOR = keccak256(
 			abi.encode(
			keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
			keccak256(bytes(name)),
			keccak256(bytes('1')),
			chainId,
			address(this)
 			)
		);
	 }
	function _mint(address to, uint value) internal {
		totalSupply = totalSupply.add(value);
		balanceOf[to] = balanceOf[to].add(value);
         		emit Transfer(address(0), to, value);
	}
	function _transfer(address from, address to, uint value) private {
		balanceOf[from] = balanceOf[from].sub(value);
 		balanceOf[to] = balanceOf[to].add(value);
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
}
