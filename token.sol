// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./Math.sol";

contract token{
    address public owner;   
    FT public token1;  
    FT public token2; //流动性
    uint256 public Liquidity;   //tokena的数量 
    uint256 token1Amount;    //tokenb的数量
    uint256 token2Amount;   //流动性证明总量
    mapping(address => uint256) public tokenA;   //交易池，本合约地址的余额
    mapping(address => uint256) public tokenB;  
    uint256 G;

    constructor(FT _token1,FT _token2,FT _tokenA){
        owner = msg.sender;
        token1 = _token1;
        token2 = _token2;
        tokenA = _tokenA;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, " the not contract owner");
        _;
    }

    // 返回token1的地址
    function getA() public view returns(address) {
        return token1;
    }

    // 返回token2的地址
    function getB() public view returns(address) {
        return token2;
    }
  
    function first(uint256 _token1Amount,uint256 _token2Amount) public onlyOwner returns(uint256) {
        if(_token1Amount > _token2Amount){
            G = _token1Amount / _token2Amount;
        }else{
            G = _token1Amount / _token2Amount;
        }
        token1Amount = _token1Amount;
        token2Amount = _token2Amount;
        Liquidity = token1Amount * token2Amount;
        token1.transferFrom(msg.sender,address(this),_token1Amount);
        token2.transferFrom(msg.sender,address(this),_token2Amount);
        return (token1Amount, token2Amount);
    }

    //增加流动性
    function addLiquidity(uint256 _token1Amount,uint256 _token2Amount) public onlyOwner returns(uint256){
        require(_token1Amount > 0 && _token2Amount >0,"deposit can't 0")
        token1Amount += _token1Amount;
        token2Amount += _token2Amount;
        Liquidity = token1Amount * token2Amount;
        token1.transferFrom(msg.sender,address(this),_token1Amount);
        token2.transferFrom(msg.sender,address(this),_token2Amount);
        tokenB[msg.sender] += Math.sqrt(_token1Amount * _token2Amount);
        tokenA.transfer(msg.sender,Math.sqrt(_token1Amount * _token2Amount));
        return Math.sqrt(_token1Amount * _token2Amount);
    }

    //移除流动性
    function removeLiquidity(uint256 _token1Amount;uint256 _token2Amount;uint256 _tokenA) public onlyOwner returns(uint256){
        require(tokenB[msg.sender] > 0,"not provide liquidity");
        tokenB[msg.sender] -= _tokenA;
        if(_token1Amount > _token2Amount){
            _token2Amount = _tokenA / (Math.sqrt(G));
            _token1Amount = _token2Amount * G;
        }else{
            _token1Amount = _tokenA / (Math.sqrt(G));
            _token2Amount = _token1Amount * G;
        }
        token1Amount -= _token1Amount;
        token2Amount -=_token2Amount;
        Liquidity = token1Amount * token2Amount;
        token1.transfer(msg.sender,_token1Amount);
        token2.transfer(msg.sender,_token2Amount);
        tokenA.transferFrom(msg.sender,address(this),_tokenA);
        return (token1Amount, token2Amount);
    }

    //token1 换 token2
    function token1TOtoken2(uint256 _token1Amount;uint256 _token2Amount) public onlyOwner retruns(uint256){
        require(_token2Amount < token2.balanceOf(address(this)),"token2 not insufficient");
        if(_token1Amount > _token2Amount){
            _token2Amount = _token1Amount / G;
        }else{
            _token2Amount = _token1Amount * G;
        }
        token1Amount -= _token1Amount;
        token2Amount +=_token2Amount;
        Liquidity = token1Amount * token1Amount;
        //手续费
        uint256 pay = _token1Amount * (3/1000);
        //滑点
        uint256 slide = _token1Amount / _token2Amount;
        //转账
        token1.transferFrom(msg.sender,address(this),_token1Amount);
        token2.transfer(msg.sender,_token2Amount - pay);
        token2.transfer(owner,pay);
        return _token2Amount - pay;

    }

    //token2 换 token1
    function token2TOtoken1(uint256 _token1Amount;uint256 _token2Amount) public onlyOwner retruns(uint256){
        require(_token1Amount < token1.balanceOf(address(this)),"token1 not insufficient");
        if(_token1Amount > _token2Amount){
            _token1Amount = _token2Amount * G;
        }else{
            _token1Amount = _token2Amount / G;
        }
        token1Amount += _token1Amount;
        token2Amount -=_token2Amount;
        Liquidity = token1Amount * token2Amount;
        //手续费
        uint256 pay = _token2Amount * (3/1000);
        //滑点
        uint256 slide = _token2Amount / _token1Amount;
        //转账
        token1.transfer(msg.sender,_token1Amount - pay);
        token1.transfer(owner,pay);
        token2.transferFrom(msg.sender,address(this),_token2Amount);
        return _token1Amount - pay;
    }

    //查询
    function consultA() public view returns(uint256) {
        return token1.balanceOf(address(this));
    }
    function consultB() public view returns(uint256) {
        return token2.balanceOf(address(this));
    }
}
