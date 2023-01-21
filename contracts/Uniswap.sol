// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./Math.sol";

contract Uniswap{
    //合约拥有者
    address public owner;
    //tokena的地址
    FT public tokena;
    //tokenb的地址
    FT public tokenb;
    //流动性
    uint256 public liquidity; 
    //tokena的数量 
    uint256 tokenaAmount;
    //tokenb的数量
    uint256 tokenbAmount;
    //流动性证明总量
    mapping(address => uint256) public tokenLPT;
    //交易池，本合约地址的余额
    mapping(address => uint256) public tokenUser;
    //比例  
    uint256 k;

    constructor(FT _tokena,FT _tokenb,FT _tokenLPT){
        owner = msg.sender;
        tokena = _tokena;
        tokenb = _tokenb;
        tokenLPT = _tokenLPT;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, " the not contract owner");
        _;
    }

    // 返回tokena的地址
    function getA() public view returns(address) {
        return tokena;
    }

    // 返回tokenb的地址
    function getB() public view returns(address) {
        return tokenb;
    }

    //初始化
    function First(uint256 _tokenaAmount,uint256 _tokenbAmount) public onlyOwner returns(uint256) {
        if(_tokenaAmount > _tokenbAmount){
            k = _tokenaAmount / _tokenbAmount;
        }else{
            k = _tokenbAmount / _tokenaAmount;
        }
        tokenaAmount = _tokenaAmount;
        tokenbAmount = _tokenbAmount;
        liquidity = tokenaAmount * tokenbAmount;
        tokena.transferFrom(msg.sender,address(this),_tokenaAmount);
        tokenb.transferFrom(msg.sender,address(this),_tokenbAmount);
        return (tokenaAmount, tokenbAmount);
    }

    //增加流动性
    function liquidityAdd(uint256 _tokenaAmount,uint256 _tokenbAmount) public onlyOwner returns(uint256){
        require(_tokenaAmount > 0 && _tokenbAmount >0,"deposit can't 0")
        tokenaAmount += _tokenaAmount;
        tokenbAmount += _tokenbAmount;
        liquidity = tokenaAmount * tokenbAmount;
        tokena.transferFrom(msg.sender,address(this),_tokenaAmount);
        tokenb.transferFrom(msg.sender,address(this),_tokenbAmount);
        tokenUser[msg.sender] += Math.sqrt(_tokenaAmount * _tokenbAmount);
        tokenLPT.transfer(msg.sender,Math.sqrt(_tokenaAmount * _tokenbAmount));
        return Math.sqrt(_tokenaAmount * _tokenbAmount);
    }

    //移除流动性
    function liquidityDel(uint256 _tokenaAmount;uint256 _tokenbAmount;uint256 _tokenLPT) public onlyOwner returns(uint256){
        require(tokenUser[msg.sender] > 0,"not provide liquidity");
        tokenUser[msg.sender] -= _tokenLPT;
        if(_tokenaAmount > _tokenbAmount){
            _tokenbAmount = _tokenLPT / (Math.sqrt(k));
            _tokenaAmount = _tokenbAmount * k;
        }else{
            _tokenaAmount = _tokenLPT / (Math.sqrt(k));
            _tokenbAmount = _tokenaAmount * k;
        }
        tokenaAmount -= _tokenaAmount;
        tokenbAmount -=_tokenbAmount;
        liquidity = tokenaAmount * tokenbAmount;
        tokena.transfer(msg.sender,_tokenaAmount);
        tokenb.transfer(msg.sender,_tokenbAmount);
        tokenLPT.transferFrom(msg.sender,address(this),_tokenLPT);
        return (tokenaAmount, tokenbAmount);
    }

    //交易，手续费，滑点功能
    //tokena 换 tokenb
    function tokenaBYtokenb(uint256 _tokenaAmount;uint256 _tokenbAmount) public onlyOwner retruns(uint256){
        require(_tokenbAmount < tokenb.balanceOf(address(this)),"tokenb not insufficient");
        if(_tokenaAmount > _tokenbAmount){
            _tokenbAmount = _tokenaAmount / k;
        }else{
            _tokenbAmount = _tokenaAmount * k;
        }
        tokenaAmount -= _tokenaAmount;
        tokenbAmount +=_tokenbAmount;
        liquidity = tokenaAmount * tokenbAmount;
        //手续费
        uint256 free = _tokenaAmount * (3/1000);
        //滑点
        uint256 slide = _tokenaAmount / _tokenbAmount;
        //转账
        tokena.transferFrom(msg.sender,address(this),_tokenaAmount);
        tokenb.transfer(msg.sender,_tokenbAmount - free);
        tokenb.transfer(owner,free);
        return _tokenbAmount - free;

    }

    //tokenb 换 tokena
    function tokenbBYtokena(uint256 _tokenaAmount;uint256 _tokenbAmount) public onlyOwner retruns(uint256){
        require(_tokenaAmount < tokena.balanceOf(address(this)),"tokena not insufficient");
        if(_tokenaAmount > _tokenbAmount){
            _tokenaAmount = _tokenbAmount * k;
        }else{
            _tokenaAmount = _tokenbAmount / k;
        }
        tokenaAmount += _tokenaAmount;
        tokenbAmount -=_tokenbAmount;
        liquidity = tokenaAmount * tokenbAmount;
        //手续费
        uint256 free = _tokenbAmount * (3/1000);
        //滑点
        uint256 slide = _tokenbAmount / _tokenaAmount;
        //转账
        tokena.transfer(msg.sender,_tokenaAmount - free);
        tokena.transfer(owner,free);
        tokenb.transferFrom(msg.sender,address(this),_tokenbAmount);
        return _tokenaAmount - free;

    }

    //查询
    function demandA() public view returns(uint256) {
        return tokena.balanceOf(address(this));
    }
    function demandB() public view returns(uint256) {
        return tokenb.balanceOf(address(this));
    }


}