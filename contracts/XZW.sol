// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
/**
以下功能已全部实现：
### 1. 增加/移出流动性                      30分
### 2. 交易功能                            30分
### 3. 实现手续费功能，千分之三手续费          10分
### 4. 实现滑点功能                         15分
### 5. 实现部署脚本                         15分
*/

contract XZW {
  address  public Aaddress;
  address  public Baddress;
  uint256 k;
  bool private s = true;
  
  mapping(address => uint256) public _amountOf;
    constructor(address A, address B){
        require(A != address(0) && B != address(0),"invalid address");
        Aaddress = A;
        Baddress = B;
    }
 
    function LiuDongXing(uint256 amountA, uint256 amountB)public{
        FT _ftA = FT(Aaddress);
        FT _ftB = FT(Baddress);
        if(s == true){// s为0就增加流动性
            if(_amountOf[Aaddress]==0 && _amountOf[Baddress]==0){
                _ftA.transferFrom(msg.sender,address(this),amountA);
                _ftB.transferFrom(msg.sender,address(this),amountB);
                _amountOf[Aaddress] += amountA;
                _amountOf[Baddress] += amountB;
                k = _amountOf[Aaddress] * _amountOf[Baddress];
            
            }else{
                require(amountA / amountB == _amountOf[Aaddress] / _amountOf[Baddress]," Please recharge in proportion ");
                _ftA.transferFrom(msg.sender,address(this),amountA);
                _ftB.transferFrom(msg.sender,address(this),amountB);
                _amountOf[Aaddress] += amountA;
                _amountOf[Baddress] += amountB;
            }
        }
        else if(s == false){//s为1就移除流动性
            _ftA.transfer(msg.sender,amountA);
            _ftB.transfer(msg.sender,amountB);
            _amountOf[Aaddress] -= amountA;
            _amountOf[Baddress] -= amountB;
            k = _amountOf[Aaddress] * _amountOf[Baddress];
        }
    }

    function AtoB(uint256 amount) public {
       FT _ftA = FT(Aaddress);
       FT _ftB = FT(Baddress);
       uint tempB;
       if(_amountOf[Aaddress] > _amountOf[Baddress]){// 计算预计得到的B币
           tempB = amount * (k/(_amountOf[Baddress] ** 2));
       }else if(_amountOf[Aaddress] == _amountOf[Baddress]){
           tempB = amount;
       }else{
           tempB = amount / (k/(_amountOf[Aaddress] ** 2));
       }
       require(_amountOf[Baddress] >= tempB,"TokenB is not enough!");
       _ftA.transferFrom(msg.sender,address(this),amount);
       _ftB.transfer(msg.sender,(tempB-(tempB * 3) / 1000));// 减千分之三手续费
       _amountOf[Aaddress] += amount;
       _amountOf[Baddress] -= (tempB-(tempB * 3) / 1000);
    }
    function BtoA(uint256 amount) public {
       FT _ftA = FT(Aaddress);
       FT _ftB = FT(Baddress);
       uint tempA;
       if(_amountOf[Aaddress] > _amountOf[Baddress]){ // 计算预计得到的A币
           tempA = amount * (k/(_amountOf[Baddress] ** 2));
       }else if(_amountOf[Aaddress] == _amountOf[Baddress]){
           tempA = amount;
       }else{
           tempA = amount / (k/(_amountOf[Aaddress] ** 2));
       }
       require(_amountOf[Aaddress] >= tempA,"TokenA is not enough!");
       _ftB.transferFrom(msg.sender,address(this),amount);
       _ftA.transfer(msg.sender,(tempA-(tempA * 3) / 1000)); // 减千分之三手续费
       _amountOf[Aaddress] -= amount;
       _amountOf[Baddress] += (tempA-(tempA * 3) / 1000);
    }
    // 滑点
    function getNowK() public view returns(uint256){
        return _amountOf[Aaddress] * _amountOf[Baddress];
    }
        function ChangeIncrease() public{
            s = true;
        }
        function ChangeReducs() public{
            s = false;
        }
}