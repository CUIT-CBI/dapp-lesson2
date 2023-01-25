pragma solidity =0.5.16;

import 'Factory.sol';
import 'Pair.sol';

contract Factory is IFactory {
	
	mapping(address => mapping(address => address)) public getPair;
	address[] public allPairs;
 	event PairCreated(address indexed token0, address indexed token1, address pair, uint);

	function allPairsLength() external view returns (uint) {

 		return allPairs.length;
 	}
 	function createPair(address tokenA, address tokenB) external returns (address pair) {
		(address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(getPair[token0][token1] == address(0), 'IERC20: PAIR_EXISTS');
		bytes memory bytecode = type(Pair).creationCode; 
	
		bytes32 salt = keccak256(abi.encodePacked(token0, token1));
		assembly {
 			pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
		}
	}
 	function setFeeToSetter(address _feeToSetter) external {
 		require(msg.sender == feeToSetter, 'ERC20: FORBIDDEN');
 		feeToSetter = _feeToSetter;
	 }
}
