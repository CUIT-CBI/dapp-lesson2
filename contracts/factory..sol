// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Factory.sol';
import './SwapPair.sol';

contract factory{

    //����������factory��Լ��ʼ��ʱ���������ѹ���Ա��ַ
    constructor(
        address _feeToSetter//�����ѹ���Ա��ַ
    ) public {
        feeToSetter = _feeToSetter;
    }

    address public feeTo;//����ǧ��֮�������ѵĵ�ַ/�����ѽ��յ�ַ
    address public feeToSetter;//�����ѹ���Ա��ַ
    
    // address public tokenA_pool;//���tokenA�Ľ��׳���
    // address public tokenB_pool;//���tokenB�Ľ��׳���
    //���ת�������ִ��Ҵ�ŵĵ�ַ/�����Գ�
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;//�ʽ������
    
    event catePair_event(address indexed token0, address indexed token1, address pair, uint);
    
    

    //��ѯ�ʽ�ص�����
    function allPairsLength() external view returns(uint){
        return allPairs.length;
    }

    //����tokenA��tokenB�ĵ�ַ�����ʽ�صĵ�ַ
    function createPair (
        address tokenA, //tokenA�ĵ�ַ
        address tokenB//tokenB�ĵ�ַ
    ) external returns (
        address pair//�ʽ�صĵ�ַ
    ) {
        //������ַ���ܹ���ͬ
        require(tokenA != tokenB,'identical_addresses');
        //ͳһ�������ҵ�ǰ��˳�򣬽�С�ķ���ǰ�棬��ֹ�����ظ��Ĵ��Ҷԣ�����(a,b)��(b,a)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        //ȷ����ַ��Ϊ��
        require(token0 != address(0),'zero_address');
        //�жϴ��Ҷ��Ƿ��Ѿ�����
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS');
        //��ȡUniswaV2Pair��Լ���ֽ���
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        //ʹ�ò���token0,token1����salt
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        //ʹ��create2����pair��Լ
        assembly {
            //create2(������Լ���͵� ETH ������bytecode ��ʼλ�á�bytecode ���ȡ����ɺ�Լ��ַ�������ֵ)
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //pair��Լ��ʼ��
        IUniswapV2Pair(pair).initialize(token0, token1);
        //��¼token0,token1�������ʽ�ص�ַ��pair
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        //��pair pull���ʽ��������
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
    
    //���������ѽ��ܵ�ַ
    function setFeeTo(address _feeTo) external {
        //���������Ƿ��������ѹ���Ա
        require(msg.sender == feeToSetter, 'forbidden');
        feeTo = _feeTo;
    }

    //�����û���ַ
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'forbidden');
        feeToSetter = _feeToSetter;
    }

}