// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FT.sol";

contract TestContract {

    using Math for uint256;

    uint256 private reserve0;
    uint256 private reserve1;

    address public hostAddress;

    address public token0;
    address public token1;
    address public LPtoken;

    uint32 private blockTimestampLast;

    uint256 public ratio;

    uint256 public KValue;

    bool public isHigher;
    mapping(address => uint256) ownTokens;



    event Swap(address indexed tokenA,uint256 tokenAout,address indexed tokenB,uint256 tokenBout);
    event Sync(uint256 reserve0,uint256 reserve1);

   constructor(address _LPtoken,address _token0,address _token1){
       token0 = _token0;
       token1 = _token1;
       LPtoken = _LPtoken;

       hostAddress = msg.sender;
   }


   modifier onlyHost() {
       require(msg.sender == hostAddress,"only Host");
       _;
   }

    function getReserves() public view returns(
        uint256 _reserve0,
        uint256 _reserve1,
        uint32 _blockTimestampLast
    ){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }


   function _update(uint256 balance0,uint256 balance1,uint256 _reserve0,uint256 _reserve1) private {
       uint32 blockTimestamp = uint32(block.timestamp % 2**32);
       uint32 timeElapsed = blockTimestamp - blockTimestampLast; 

       reserve0 = uint256(balance0);
       reserve1 = uint256(balance1);
       blockTimestampLast = blockTimestamp;

       emit Sync(reserve0,reserve1);

}

    /*
    s = optimal swap amount
    r = amount of reserve for tokenA
    a = amount of token a the user currently has ( not added to reserve yet)
    f = swap fee percent
    s = ( sqrt ((( 2 -f )r) ^ 2 + 4(1 - f)ar) - ( 2 -f)r) / (2(1 - f))
    */


  function initPool(uint256 _reserve0,uint256 _reserve1) public payable onlyHost{
     reserve0 = _reserve0;
     reserve1 = _reserve1;
     KValue= reserve0.mul(reserve1);

    if(reserve0 > reserve1) {
        ratio = reserve0 / reserve1;
        isHigher = true;
    }else{
        ratio = reserve1 / reserve0;
        isHigher = false;
    }

    IERC20(token0).transferFrom(msg.sender,address(this),_reserve0);
    IERC20(token1).transferFrom(msg.sender,address(this),_reserve1);
  }

  function addLiquidity(uint256 token0In,uint256 token1In) public payable{
       (uint256 _reserve0,uint256 _reserve1,) = getReserves();

       _reserve0 += token0In;
       _reserve1 += token1In;


       uint256 userIn = token0In.mul(token1In);
       ownTokens[msg.sender] +=userIn.sqrt();

       IERC20(token0).transferFrom(msg.sender,address(this),token0In);
       IERC20(token1).transferFrom(msg.sender,address(this),token1In);
       IERC20(LPtoken).transfer(msg.sender,userIn.sqrt());


       uint256 balance0 = ERC20(token0).balanceOf(address(this));
       uint256 balance1 = ERC20(token1).balanceOf(address(this));
       _update(balance0,balance1,_reserve0,_reserve1);
       KValue = uint256(reserve0).mul(reserve1);

  }


    function removeLiquidity(uint256 amountOf) public payable{
     require (amountOf >0,"INVALID_AMOUNT");
     require (ownTokens[msg.sender] > 0,"NO_SUFFICIENT_BALANCE");
     (uint256 _reserve0,uint256 _reserve1,) = getReserves();

        uint256 _amount0;
        uint256 _amount1;

       if(isHigher){
           _amount1 = amountOf / (ratio.sqrt());
           _amount0 = _amount1 * ratio;
       }else{
           _amount0= amountOf / (ratio.sqrt());
           _amount1 = _amount0 / ratio;
       }

       _reserve0 -= _amount0;
       _reserve1 -= _amount1;


       ownTokens[msg.sender] -= amountOf;

       IERC20(LPtoken).transferFrom(msg.sender,address(this),amountOf);
       IERC20(token0).transfer(msg.sender,_amount0);
       IERC20(token1).transfer(msg.sender,_amount1);
       uint256 balance0 = IERC20(token0).balanceOf(address(this));
       uint256 balance1 = IERC20(token1).balanceOf(address(this));





       balance0 = IERC20(token0).balanceOf(address(this));
       balance1 = IERC20(token1).balanceOf(address(this));

       _update(balance0,balance1,_reserve0,_reserve1);
       KValue = uint256(reserve0).mul(reserve1);



  }

  function _swap(address tokenType,uint256 amountOut) public payable returns(uint256){
      require(tokenType == token0 || tokenType == token1,"INVALID_TOKEN");
      (uint256 _reserve0,uint256 _reserve1,) = getReserves();

      uint256 tokenAnotherAmount;
      address tokenAnother;

      if(tokenType == token0){
          tokenAnother = token1;
          require(amountOut <= _reserve0,'NO_SUFFICIENT_BALANCE');
          if(isHigher){
              tokenAnotherAmount = amountOut.div(ratio);
          }else{
              tokenAnotherAmount = amountOut.mul(ratio);
          }
           _reserve0 -= amountOut;
           _reserve1 += tokenAnotherAmount.mul(997).div(1000);
           KValue = _reserve0.mul(_reserve1);


      }else{
          tokenAnother = token0;
          require(amountOut <= _reserve1,'NO_SUFFICIENT_BALANCE');
          if(isHigher){
              tokenAnotherAmount = amountOut.mul(ratio);
          }else{
              tokenAnotherAmount = amountOut.div(ratio);
          }

          _reserve1 -= amountOut;
          _reserve0 += tokenAnotherAmount.mul(997).div(1000);
          KValue = _reserve0.mul(_reserve1);


      }

          IERC20(tokenType).transferFrom(msg.sender,address(this),amountOut);
          IERC20(tokenAnother).transfer(msg.sender,tokenAnotherAmount.mul(997).div(1000));

           emit Swap(tokenType,amountOut,tokenAnother,tokenAnotherAmount);

           return tokenAnotherAmount.mul(997).div(1000);

  }


  address private owner;
  bool _isDIS = true;

  uint256 maxPledgeAmount; 
  uint256 leftMiningAmount; 
  uint256 size; 

  uint256 totalPledgeAmount; 
  uint256 startTime;
  uint256 endTime;

  mapping(address => uint256) indexOfMiners;

  struct PledgeOrder {
      bool isExist;  
      address ple;
      address tokenT;        
      uint256 tokenAmount;  
      uint256 profitToken;   
      uint256 lastBlock;  
      uint256 index;

  }

  PledgeOrder[] public orders;

  struct KeyFlag {
      address key;
      bool isExist;
  }

  function setMaxPledge(uint256 _maxPledgeAmount) public {
      maxPledgeAmount = _maxPledgeAmount;
  }

   function setTime(uint256 _startTime,uint256 _endTime) public {
       require(_endTime > _startTime,'INVALID_TIME');
       startTime = _startTime;
       endTime =_endTime;
   }

  function tokenPledgeIn(address tokenType,uint256 pledgeAmount) public payable{
      require(address(msg.sender) == address(tx.origin),'INVALID_CONTRACT');
      require(_isDIS,'FAILED');
      require(pledgeAmount > 0,"INVALID_AMOUNT");
      require(block.timestamp >= startTime && block.timestamp <= endTime,"OUT_OF_TIME");
      (uint256 _reserve0,uint256 _reserve1,) = getReserves();
      uint256 _amount;

      if(tokenType == token0){

          if(isHigher){
              _amount = pledgeAmount.div(ratio.sqrt());
          }else{
              _amount = pledgeAmount.mul(ratio.sqrt());
          }
          _reserve0 += pledgeAmount;

      }else{

          if(isHigher){
              _amount = pledgeAmount.mul(ratio.sqrt());
          }else{
              _amount = pledgeAmount.div(ratio.sqrt());
          }
          _reserve1 += pledgeAmount;
      }



       PledgeOrder memory pledger; 
       pledger = PledgeOrder(true,msg.sender,tokenType,_amount,0,block.number,size);
       indexOfMiners[msg.sender] = size;
       orders.push(pledger);
       size++;

       KValue = _reserve0 * _reserve1;
       IERC20(tokenType).transferFrom(msg.sender,address(this),pledgeAmount);

  }

  function getProfit() public payable returns(uint256){

      (uint256 _reserve0,uint256 _reserve1,) = getReserves();
      PledgeOrder memory pledger = orders[indexOfMiners[msg.sender]];

      uint256 _amountOld = pledger.tokenAmount;
      uint256 _time = pledger.lastBlock;
      address tokenType = pledger.tokenT;

      require(_amountOld > 0 && _time >0,'INVALID_OPERATION');
      uint256 _amountLast;
      if(tokenType == token0){
           if(isHigher){
              _amountLast = _amountOld.mul(ratio.sqrt());
          }else{
              _amountLast = _amountOld.div(ratio.sqrt());
          }

          _reserve0 -= _amountLast;
      }else{
          if(isHigher){
              _amountLast = _amountOld.div(ratio.sqrt());
          }else{
              _amountLast = _amountOld.mul(ratio.sqrt());
          }

          _reserve1 -= _amountLast;
      }

      uint256 reward = _amountOld.mul(block.number.sub(_time)).div(2000);

      pledger.lastBlock = 0;
      pledger.tokenAmount = 0;

      pledger.profitToken = _amountLast.sub(_amountOld).add(reward);

      KValue = _reserve0.mul(_reserve1);
      IERC20(tokenType).transfer(msg.sender,_amountLast);
      IERC20(LPtoken).transfer(msg.sender,reward);

      return reward;

  }
}
