pragma solidity ^0.8.0;

import "./FT.sol";

//交易池 
contract LooneySwapPool is FT{
    
    // 合约拥有者
    address public owner;
    //合约地址
    FT public token0;
    FT public token1;
    // 余额 token0 
    uint256 public reserve0; 
    // 余额 token1 
    uint256 public reserve1; 
    //初始流动性为零 liquidity / totalSupply = amount / reserve
    uint256 liquidity = 0;
     // 比例
    uint256 public proportion;
    // 是否已初始化
    int public flag = 0;
    uint256 amount0;
    uint256 amount1;
    
    constructor(FT _token0, FT _token1) FT("Liquidity","LX") {
    owner = msg.sender;
    token0 = _token0;
    token1 = _token1;
   }
   
   //判断合约调用是否为合约拥有者
   modifier o {nlyOwner()
        require(msg.sender == owner, "not the contract's owner");
        _;
    }

    // 判断是否已经添加
    modifier hasAdd() {
        require(flag == 1, "don't call the function add firstly");
        _;
    }

   //添加流动性
   //第一次调用 add 指定我们存入代币的数量
   function add(uint amount0, uint amount1) external payable onlyOwner(){
    //判断
    require(flag == 0); 
    flag = 1;
    //用户将代币转移至池中 
    token0.transferFrom(msg.sender, address(this), _amount0);
    token1.transferFrom(msg.sender, address(this), _amount1);
    
    reserve0 = amount0;
    reserve1 = amount1;
       
    //liquidity = sqrt(amount0 * amount1)
    liquidity = sqrt(_amount0 * _amount1);
    
    _mint(msg.sender, liquidity); 
   }
  

    function addLiquidity(address _token, uint256 _amount) external payable hasAdd() returns (uint256) {
        require(_token == token0 || _token == token1, "Incorrect address");
        token0.balanceOf(address(this));
        token1.balanceOf(address(this));
        if(_token == token1){
            amount1 = _amount;
            amount0 = reserve1 * amount0 / reserve1;            
        } else {
            amount0 = _amount;
            amount1 = reserve1 * amount0 / reserve0;
        }

        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);
       
        liquidity = min(totalSupply() * amount0 / reserve0, totalSupply() * amount1 / reserve1);
        //铸造代币
        _mint(msg.sender, liquidity);
        
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
        
        return liquidity;
    }
    //移除流动性
   function removeLiquidity(uint256 _amount) external payable hasAdd() returns (uint256, uint256) {
        require(_amount > 0, "_amount > zero");
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        //amount0 / balance0 = _amount / tatalSupply
        amount0 = _amount * balance0 / totalSupply();
        //amount1 / balance1 = _amount / tatalSupply
        amount1 = _amount * balance1 / totalSupply();
        
        //销毁代币
        _burn(msg.sender, _amount);

        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        return (amount0, amount1);
    }
    //实现手续费功能，获取返回给用户的代币数量 滑点是指预期交易价格和实际成交价格之间的差值
     function token0ToToken1(uint256 putToken0Amount, uint256 _minTokens)
        external
        payable
        hasAdd()
        returns(uint256 getToken1Amount)
    {   
        require(putToken0Amount > 0 && reserve1 > 0, " error")
        //收取千分之三手续费
        uint256 putAmountWithFee = putToken0Amount * 997;
        uint256 a = putAmountWithFee * reserve1;
        uint256 b = (reserve0 * 1000) + putAmountWithFee; 
        uint256 getAmount = a/b;
        require(getAmount >= _minTokens, "Incorrect putToken0Amount");  
        reserve0 += putToken0Amount;
        reserve1 -= getAmount;

        token0.transferFrom(msg.sender, address(this), putToken0Amount);
        token1.transferFrom(msg.sender, address(this), getAmount);  
        //更新余额
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));   
        
    }
    
    function token1ToToken0(uint256 putToken1Amount, uint256 _minTokens)
        external
        payable
        hasAdd()
        returns(uint256 getToken1Amount)
    {   
        require(putToken1Amount > 0 && reserve0 > 0, " error")
        //收取千分之三手续费
        uint256 putAmountWithFee = putToken1Amount * 997;
        uint256 a = putAmountWithFee * reserve0;
        uint256 b = (reserve1 * 1000) + putAmountWithFee; 
        uint256 getAmount = a/b;
        require(getAmount >= _minTokens, "Incorrect putToken0Amount");  
        reserve1 += putToken1Amount;
        reserve0 -= getAmount;

        token1.transferFrom(msg.sender, address(this), putToken1Amount);
        token0.transferFrom(msg.sender, address(this), getAmount);  
        //更新余额
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));   
        
    }
  

  //函数定义
  function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
