// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./util/IERC20.sol";
import "./console.sol";
contract Store{
    // must match with IERC20 interface
   address private token0;
   address private token1; 

   string token0Name;
   string token1Name;

   // method selector(调用erc20转账)
   bytes4 private constant SelectorTransfer = bytes4(keccak256(bytes("transfer(address,uint256)")));
   bytes4 private constant SelectorTransferFrom = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
   uint256 public token0Num;
   uint256 public token1Num;
   address private creator;
   uint32 private blockTimestrampLast;
   uint public K;
   bool private lock = false;
   event swapEvent(address indexed customer,string tokenType,uint tokenNumber);

   constructor(){
       creator = msg.sender;
   }

   // 类似于分布式锁串行化交易
   modifier locked(){
       require(lock == false,"store is used by other");
       lock = true;
       _;
       lock = false;
   }

   // 原型模式
   function initialize(address _token0,address _token1)external{
       // 检查是否匹配ERC20 interface
       //require(IERC20(_token0).totalSupply()>0, "Token0 is not a valid ERC20 token");
       //require(IERC20(_token1).totalSupply()>0, "Token1 is not a valid ERC20 token");
       token0 = _token0;
       token1 = _token1;
       token0Name = IERC20(token0).name();
       token1Name = IERC20(token1).name();
   }

   // 获取当前商店状态,能无gas消耗;
   function getStoreInfo()public view returns(uint256 _token0Num,uint256 _token1Num,uint32 _blockTimestrampLast){
       _token0Num = token0Num;
       _token1Num = token1Num;
       _blockTimestrampLast = blockTimestrampLast;
   }

   /**
    使用k值大概计算滑点损失后能获得的数量
   */
   function calculateTokenNumber(uint256 _token0Input,uint256 _token1Input)internal view returns(uint256 _token0,uint256 _token1){
       require( (_token0Input>0) || (_token1Input>0),"please promise you should exchange goods greater than zero");
       if(_token0Input<0){
           _token0Input=0;
        }
       if(_token1Input<0){
           _token1Input=0;
        }
       uint256 NewNums0=token0Num+_token0Input;
       uint256 NewNums1=token1Num+_token1Input;
       // 精度损失造成,但是因为是向下进位，代理商不会损失就行
       // 浮点数除法，保留六位小数,扩大分子因子
       _token0=_token1Input!=0? uint256(NewNums0-K/NewNums1):0;
       _token1=_token0Input!=0? uint256(NewNums1-K/NewNums0):0;
    }

    /**
    * 用户展示层:滑点预计算用token0购买token1,保留两位小数
    */
   function slipeCalFromToken0(uint256 _token0Input)external view returns(uint  ratio){
       require(_token0Input<token0Num,"invaild input");
       //理论获得
       uint256 theoryObtain = uint256((_token0Input * token0Num*10**6/token1Num)/10**6);
       //最终获得,排除手续费
       (,uint256 eventObtain)= calculateTokenNumber(_token0Input,0);
       require(theoryObtain-eventObtain>=0,"system error");
       ratio=((theoryObtain-eventObtain)*10**6)/(theoryObtain*10**4);
   }

    /**
    * 用户展示层:滑点预计算用token1购买token0,保留两位小数
    */
   function slipeCalFromToken1(uint256  _token1Input)external view returns(uint ratio){
       require(_token1Input<token1Num,"invaild input");
       //理论获得
       uint256 theoryObtain = uint256((_token1Input * token1Num*10**6/token0Num)/10**6);
       //最终获得,排除手续费
       (uint256 eventObtain,)=calculateTokenNumber(0,_token1Input);
       ratio=((theoryObtain-eventObtain)*10**6)/(theoryObtain*10**4);
   }
   
    /**
    * AMM core function
    * _token0Input  and _token1Input must greater than zerp.
    */
   function swap(uint256 _token0Input,uint256 _token1Input,address to)internal locked{
       require(_token0Input>0||_token1Input>0,"cant valid the transaction params,please prove transaction numbers greater than zero");
       (uint256 _token0Nums,uint256 _token1Nums,)=getStoreInfo(); // 节约gas
       (uint256 _StoreGiven0,uint256 _StoreGiven1)=calculateTokenNumber(_token0Input, _token1Input);
       // 确保商店能够支付，同时保证了用户的其中一个输入必须大于0，还节省了gas
       require(_token0Nums>_StoreGiven0&&_token1Nums>_StoreGiven1,"store cant process enough goods to trade");        
       // 交易token
       // user should obtain number =  service charge+actual obtain number
       if(_StoreGiven0>0){
           uint256 serviceCharge=_StoreGiven0*3/(10**3);
           _safeTransferFrom(token0,msg.sender,address(this),serviceCharge);
           _safeTransaction(token0, to, _StoreGiven0-serviceCharge);
           // 用户给钱
           _safeTransferFrom(token1,msg.sender,address(this),_token1Input);
        }
        if(_StoreGiven1>0){
           uint256 serviceCharge=_StoreGiven1*3/(10**3);
           _safeTransferFrom(token1,msg.sender,address(this),serviceCharge);
           _safeTransaction(token1, to, _StoreGiven1-serviceCharge);
           // 用户给钱
           _safeTransferFrom(token0,msg.sender,address(this),_token0Input);
        }
        token1Num=token1Num-_StoreGiven1+_token1Input;
        token0Num=token0Num-_StoreGiven0+_token0Input; 
        _update(IERC20(token0).balanceOf(address(this)),IERC20(token1).balanceOf(address(this)));
   }
  
    /**
    * 用户展示层:提供交易方法
    */
   function swapFromToken0(uint256 _tokenNums0,address to)external{
       swap(_tokenNums0,0,to);
       emit swapEvent(msg.sender,token0Name,_tokenNums0);
   }

   function swapFromToken1(uint256 _token1Nums,address to)external{
       swap(0,_token1Nums,to);
       emit swapEvent(msg.sender,token1Name,_token1Nums);
   }

    /**
    * 保证不可见,同时降低函数耦合度
    */
   function _safeTransaction(address token,address to,uint value)private{
       (bool success,bytes memory data) = token.call(abi.encodeWithSelector(SelectorTransfer, to,value));
       // 确保交易正确，同时不会直接panic
       require(success&&(data.length == 0 || abi.decode(data,(bool))),"transaction failed,because the store given error");
   }

   function _safeTransferFrom(address token,address from,address to ,uint value)private{
       (bool success,bytes memory data) = token.call(abi.encodeWithSelector(SelectorTransferFrom,from,to,value));
       // 确保交易正确，同时不会直接panic
       require(success&&(data.length == 0 || abi.decode(data,(bool))),"transaction failed,because the store transferFrom error");
   }

   function _update(uint balances0,uint balances1)internal{
       require(balances0 == uint256(balances0)&& balances1 == uint256(balances1),"store has too much money,spend more");
       blockTimestrampLast= uint32(block.timestamp);
       token0Num=uint256(balances0);
       token1Num=uint256(balances1);
       K=token1Num*token0Num;
   }
   
   function syncBalance()external locked{
       _update(IERC20(token0).balanceOf(address(this)),IERC20(token1).balanceOf(address(this)));
   }
    
}

