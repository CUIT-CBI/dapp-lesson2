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



	// 事件：当 tokenA 交换成 tokenB 时，会触发该事件
	event Swap(address indexed tokenA, uint256 tokenAout, address indexed tokenB, uint256 tokenBout);

	// 事件：当流动性池的储备量发生变化时，会触发该事件
	event Sync(uint256 reserve0, uint256 reserve1);

	// 构造函数：初始化合约实例时，需要传入流动性代币的地址、token0 的地址和 token1 的地址
	constructor(address _LPtoken, address _token0, address _token1){
	token0 = _token0;
	token1 = _token1;
	LPtoken = _LPtoken;
	hostAddress = msg.sender;
	}

	// 修饰器：仅限主机调用该函数
	modifier onlyHost() {
	require(msg.sender == hostAddress, "仅限主机调用");
	_;
	}

	// 函数：获取当前流动性池的储备量，返回 token0 和 token1 的储备量以及最后一次变化的时间戳
	function getReserves() public view returns(
	uint256 _reserve0,
	uint256 _reserve1,
	uint32 _blockTimestampLast
	){
	_reserve0 = reserve0;
	_reserve1 = reserve1;
	_blockTimestampLast = blockTimestampLast;
	}


	function _update(uint256 balance0, uint256 balance1, uint256 _reserve0, uint256 _reserve1) private {
		   // 获取当前块时间的低 32 位（精确到秒），以便计算时间间隔
		   uint32 blockTimestamp = uint32(block.timestamp % 2**32);
		   // 计算与上次同步时间之间的时间差
		   uint32 timeElapsed = blockTimestamp - blockTimestampLast; 

		   // 更新储备量
		   reserve0 = uint256(balance0);
		   reserve1 = uint256(balance1);
		   // 更新上次同步时间为当前块时间
		   blockTimestampLast = blockTimestamp;

		   // 发送 Sync 事件，通知所有监听器储备量已更新
		   emit Sync(reserve0, reserve1);
	}

	/*
	s = optimal swap amount
	r = amount of reserve for tokenA
	a = amount of token a the user currently has ( not added to reserve yet)
	f = swap fee percent
	s = (sqrt(((2-f)r)^2+4(1-f)ar)-(2-f)r)/(2(1-f))
	*/

	// 初始化流动性池子，只有合约创建者可以调用
	function initPool(uint256 _reserve0, uint256 _reserve1) public payable onlyHost {
		// 初始化储备量
		reserve0 = _reserve0;
		reserve1 = _reserve1;
		// 计算乘积 K
		KValue = reserve0.mul(reserve1);
		// 比较两个代币的储备量，决定哪个代币价格更高
		if (reserve0 > reserve1) {
			ratio = reserve0 / reserve1;
			isHigher = true;
		} else {
			ratio = reserve1 / reserve0;
			isHigher = false;
		}
		// 从调用者转入代币到流动性池子中
		IERC20(token0).transferFrom(msg.sender, address(this), _reserve0);
		IERC20(token1).transferFrom(msg.sender, address(this), _reserve1);
	}

	// 添加流动性
	function addLiquidity(uint256 token0In,uint256 token1In) public payable {
		// 获取当前储备量
		(uint256 _reserve0,uint256 _reserve1,) = getReserves();

		// 储备量增加
		_reserve0 += token0In;
		_reserve1 += token1In;

		// 用户输入数量的乘积
		uint256 userIn = token0In.mul(token1In);
		// 用户所拥有的代币数量
		ownTokens[msg.sender] += userIn.sqrt();

		// 将代币转移到智能合约
		IERC20(token0).transferFrom(msg.sender,address(this),token0In);
		IERC20(token1).transferFrom(msg.sender,address(this),token1In);
		// 将代币LPToken转移到用户钱包
		IERC20(LPtoken).transfer(msg.sender,userIn.sqrt());

		// 获取当前余额
		uint256 balance0 = ERC20(token0).balanceOf(address(this));
		uint256 balance1 = ERC20(token1).balanceOf(address(this));
		// 更新储备量及最后更新时间
		_update(balance0,balance1,_reserve0,_reserve1);
		// 更新K值
		KValue = uint256(reserve0).mul(reserve1);
	}

	// 移除流动性
	function removeLiquidity(uint256 amountOf) public payable{
		// 验证用户输入的数量是否合法
		require (amountOf > 0,"INVALID_AMOUNT");
		// 验证用户所持有的代币数量是否足够
		require (ownTokens[msg.sender] > 0,"NO_SUFFICIENT_BALANCE");

		// 获取当前储备量
		(uint256 _reserve0,uint256 _reserve1,) = getReserves();

		uint256 _amount0;
		uint256 _amount1;

		// 判断当前储备量是否倾斜，计算移除代币的数量
		if(isHigher){
			_amount1 = amountOf / (ratio.sqrt());
			_amount0 = _amount1 * ratio;
		}else{
			_amount0= amountOf / (ratio.sqrt());
			_amount1 = _amount0 / ratio;
		}

		// 更新储备量
		_reserve0 -= _amount0;
		_reserve1 -= _amount1;

		// 更新用户所持有的代币数量
		ownTokens[msg.sender] -= amountOf;

		// 将LPToken转移到智能合约
		IERC20(LPtoken).transferFrom(msg.sender,address(this),amountOf);
		// 将代币转移到用户钱包
		IERC20(token0).transfer(msg.sender,_amount0);
		IERC20(token1).transfer(msg.sender,_amount1);

		// 获取当前余额
		uint256 balance0 = IERC20(token0).balanceOf(address(this));
		uint256 balance1 = IERC20(token1).balanceOf(address(this));
		// 更新储备量及最后更新时间
		_update(balance0,balance1,_reserve0,_reserve1);
		// 更新K值
		KValue = uint256(reserve0).mul(reserve1);
	}

	/**
	 * @dev 交换 token0 或 token1，获取另一种代币。
	 * @param tokenType 要交换的代币类型，只能为 token0 或 token1。
	 * @param amountOut 期望获得的代币数量。
	 * @return tokenAnotherAmount 实际获得的另一种代币数量。
	 */
	function _swap(address tokenType, uint256 amountOut) public payable returns (uint256) {
		// 检查要交换的代币类型是否为 token0 或 token1
		require(tokenType == token0 || tokenType == token1, "INVALID_TOKEN");

		// 获取当前储备量
		(uint256 _reserve0, uint256 _reserve1, ) = getReserves();

		// 定义变量保存另一种代币数量和地址
		uint256 tokenAnotherAmount;
		address tokenAnother;

		if (tokenType == token0) {  // 如果要交换的代币是 token0
			tokenAnother = token1;
			// 检查 token0 的储备量是否足够交换
			require(amountOut <= _reserve0, 'NO_SUFFICIENT_BALANCE');
			// 计算可以获得的 token1 数量
			if (isHigher) {
				tokenAnotherAmount = amountOut.div(ratio);
			} else {
				tokenAnotherAmount = amountOut.mul(ratio);
			}
			// 更新储备量和 K 值
			_reserve0 -= amountOut;
			_reserve1 += tokenAnotherAmount.mul(997).div(1000);
			KValue = _reserve0.mul(_reserve1);
		} else {  // 如果要交换的代币是 token1
			tokenAnother = token0;
			// 检查 token1 的储备量是否足够交换
			require(amountOut <= _reserve1, 'NO_SUFFICIENT_BALANCE');
			// 计算可以获得的 token0 数量
			if (isHigher) {
				tokenAnotherAmount = amountOut.mul(ratio);
			} else {
				tokenAnotherAmount = amountOut.div(ratio);
			}
			// 更新储备量和 K 值
			_reserve1 -= amountOut;
			_reserve0 += tokenAnotherAmount.mul(997).div(1000);
			KValue = _reserve0.mul(_reserve1);
		}

		// 将要交换的代币转移到合约账户
		IERC20(tokenType).transferFrom(msg.sender, address(this), amountOut);
		// 将获得的另一种代币转移给用户
		IERC20(tokenAnother).transfer(msg.sender, tokenAnotherAmount.mul(997).div(1000));

		// 发出 Swap 事件
		emit Swap(tokenType, amountOut, tokenAnother, tokenAnotherAmount);

		// 返回实际获得的另一种代币数量
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

		// 该函数用于将代币抵押到合约中
		function tokenPledgeIn(address tokenType,uint256 pledgeAmount) public payable{
		// 仅允许EOA账户调用该函数
		require(address(msg.sender) == address(tx.origin),'INVALID_CONTRACT');
		// 确认合约状态为"运行中"
		require(_isDIS,'FAILED');
		// 确认抵押数量大于0
		require(pledgeAmount > 0,"INVALID_AMOUNT");
		// 确认当前时间在抵押期限内
		require(block.timestamp >= startTime && block.timestamp <= endTime,"OUT_OF_TIME");
		// 获取储备资产数量
		(uint256 _reserve0,uint256 _reserve1,) = getReserves();
		uint256 _amount;

		  // 判断代币类型并计算抵押资产的数量
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

  // 将抵押订单存入orders数组
  PledgeOrder memory pledger; 
  pledger = PledgeOrder(true,msg.sender,tokenType,_amount,0,block.number,size);
  indexOfMiners[msg.sender] = size;
  orders.push(pledger);
  size++;

  // 更新K值
  KValue = _reserve0 * _reserve1;
  // 将抵押资产转入合约
  IERC20(tokenType).transferFrom(msg.sender,address(this),pledgeAmount);
  }

	// 该函数用于计算用户的收益，并将收益和抵押资产一并转回给用户
function getProfit() public payable returns(uint256){
// 获取储备资产数量
(uint256 _reserve0,uint256 _reserve1,) = getReserves();
// 获取当前用户的抵押订单信息
PledgeOrder memory pledger = orders[indexOfMiners[msg.sender]];

		  // 获取原来抵押资产数量和最后一次更新的块号
  uint256 _amountOld = pledger.tokenAmount;
  uint256 _time = pledger.lastBlock;
  address tokenType = pledger.tokenT;

  // 确认抵押订单有效
  require(_amountOld > 0 && _time >0,'INVALID_OPERATION');

  uint256 _amountLast;
  if(tokenType == token0){
       // 根据价格比例计算当前抵押资产的数量
       if(isHigher){
          _amountLast = _amountOld.mul(ratio.sqrt());
      }else{
          _amountLast = _amountOld.div(ratio.sqrt());
      }
      // 更新储备资产数量
      _reserve0 -= _amountLast;
  }else{
      // 根据价格比例计算当前抵押资产的数量
      if(isHigher){
          _amountLast = _amountOld.div(ratio.sqrt());
      }else{
          _amountLast = _amountOld.mul(ratio.sqrt());
      }
      // 更新储备资产数量

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
