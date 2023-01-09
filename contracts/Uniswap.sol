// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// 调用对应ft的函数
import "./FT.sol";
// import "./SafeMath.sol";
import "hardhat/console.sol";

// 增加/移出流动性                   ✔
// 交易功能                         ✔
// 实现手续费功能,千分之三手续费       ✔
// 实现滑点功能                      
// 实现部署脚本                      ✔

contract Uniswap{
    // tokenA地址
    address private tokenA;
    // tokenB地址
    address private tokenB;
    // // 流动性证明总量
    // uint256 private TotalLPT;
    // 当前k值
    uint256 private _k;

    // // 用户对应的流动性证明
    // mapping(address => uint256) private LPT;
    // 交易池，即本合约地址在对应ft合约的余额
    mapping(address => uint256) private pool;
    // 用户在交易池的对应ft的流动性数量
    mapping(address => mapping(address => uint256)) private liquidity;

    // 构造器，初始化输入tokenA和tokenB地址
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // 返回tokenA的地址
    function getAddrOfA() public view returns(address) {
        return tokenA;
    }

    // 返回tokenB的地址
    function getAddrOfB() public view returns(address) {
        return tokenB;
    }

    // // 返回流动性证明总量
    // function totalLPT() public view returns(uint256) {
    //     return TotalLPT;
    // }
    // 返回池中某ft的量，即本合约在对应ft的余额
    function poolAmount(address _ft) public view returns(uint256) {
        return pool[_ft];
    }
    // // 返回账户流动性证明
    // function getLPT(address _account) public view returns(uint256){
    //     return LPT[_account];
    // }
    // 更新池，即查询余额后修改池映射
    function updatePool(address _ft) internal {
        pool[_ft] = FT(_ft).balanceOf(address(this));
    }
    // 刷新，更新tokenA和tokenB的池，计算_k
    function refresh() public {
        updatePool(tokenA);
        updatePool(tokenB);
        update_K();
    }
    // 更新并返回_k
    function get_k() public view returns(uint256){
        // update_K();
        return _k;
    }
    // 更新_k
    function update_K() internal {
        _k = poolAmount(tokenA) * poolAmount(tokenB);
    }
    // 计算手续费
    function calculateFee(uint256 _fee) internal pure returns(uint256) {
        return _fee * 997 / 1000;
    }
    // 查询流动性
    function getLiquidity(address _account) public view returns(uint256 liq_a, uint256 liq_b) {
        liq_a = liquidity[_account][tokenA];
        liq_b = liquidity[_account][tokenB];
        return (liq_a, liq_b);
    }
    // 增加流动性
    // 需要先进行approve
    function addLiquidity(uint256 _a, uint256 _b) public returns(uint256 amountA, uint256 amountB) {
        require(_a != 0 || _b != 0, "invalid value");
        // 确保足够余额
        require(A_balance(msg.sender) >= _a && B_balance(msg.sender) >= _b , "Not enough balance");
        // 确保已经approve
        require(A_allowance(msg.sender, address(this)) >= _a && B_allowance(msg.sender, address(this)) >= _b, "Not enough allowance");
        // 转入ft
        FT(tokenA).transferFrom(msg.sender, address(this), _a);
        FT(tokenB).transferFrom(msg.sender, address(this), _b);
        // 更新池余额，更新_K，发生转账后马上更新
        refresh();
        // 更新流动性, 扣除手续费，手续费直接加入池中，即本合约在对应的ft的余额
        liquidity[msg.sender][tokenA] += calculateFee(_a);
        liquidity[msg.sender][tokenB] += calculateFee(_b);
        // // 权益性证明也只计算手续费后
        // LPT[msg.sender] += calculateFee(_a) * calculateFee(_b);
        // // 总权益性证明加上刚刚计算的值
        // TotalLPT += LPT[msg.sender];
        // 返回池余额，即本合约在对应ft余额
        amountA = poolAmount(tokenA);
        amountB = poolAmount(tokenB);
        return (amountA, amountB);
    }

    // 移出流动性
    function removeLiquidity(uint256 _a, uint256 _b) public returns(uint256 amountA, uint256 amountB) {
        require(_a != 0 || _b != 0, "invalid value");
        // 确保池余额足够
        require(poolAmount(tokenA) >= _a && poolAmount(tokenB) >= _b, "Not enough pool amount");
        // 确保用户流动性足够
        require(liquidity[msg.sender][tokenA] >= calculateFee(_a) && liquidity[msg.sender][tokenB] >= calculateFee(_b),"Not enough liquidity");
        // // 确保用户权益性证明足够
        // require(LPT[msg.sender] >= _a * _b, "Not enough LPT");
        // 更新流动性, 扣除手续费，手续费直接加入池中，即本合约在对应的ft的余额
        liquidity[msg.sender][tokenA] -= calculateFee(_a);
        liquidity[msg.sender][tokenB] -= calculateFee(_b);
        // // 权益性证明也只计算手续费后
        // uint256 calculatedLPT = calculateFee(_a) * calculateFee(_b);
        // // 减去计算值
        // LPT[msg.sender] -= calculatedLPT;
        // // 总权益性证明也减去刚刚计算的值
        // TotalLPT -=  calculatedLPT;
        // 转出扣除手续费之后的ft
        FT(tokenA).transfer(msg.sender, calculateFee(_a));
        FT(tokenB).transfer(msg.sender, calculateFee(_b));
        // 更新池余额，更新_K，发生转账后马上更新
        refresh();
        // 返回池余额，即本合约在对应ft余额
        amountA = poolAmount(tokenA);
        amountB = poolAmount(tokenB);
        return (amountA, amountB);
    }

    // 交易
    // 需要先进行approve
    // 用确切数量的tokenA交易得到计算值的tokenB
    function swapExactAforB(uint256 _a) public returns(uint256 amountA, uint256 amountB) {
        uint256 _calculateB = calculateExactAForB(_a);
        require(_a != 0, "invalid value");
        require(poolAmount(tokenB) >= _calculateB, "Not enough token");
        // 转入ft
        FT(tokenA).transferFrom(msg.sender, address(this), _a);
        require(calculateExactAForB(_a) == _calculateB, "pool has changed");
        // 转出扣除手续费之后的ft
        FT(tokenB).transfer(msg.sender, _calculateB);
        // 更新池余额，更新_K，发生转账后马上更新
        // 交易无需更新流动性和权益性证明
        refresh();
        // 返回池余额，即本合约在对应ft余额
        amountA = poolAmount(tokenA);
        amountB = poolAmount(tokenB);
        return (amountA, amountB);
    }

    // 用确切数量的tokenB交易得到计算值的tokenA
    function swapExactBforA(uint256 _b) public returns(uint256 amountA, uint256 amountB) {
        uint256 _calculateA = calculateExactBForA(_b);
        require(_b != 0, "invalid value");
        require(poolAmount(tokenA) >= _calculateA, "Not enough token");
        // 转入ft
        FT(tokenB).transferFrom(msg.sender, address(this), _b);
        require(calculateExactBForA(_b) == _calculateA, "pool has changed");
        // 转出扣除手续费之后的ft
        FT(tokenA).transfer(msg.sender, _calculateA);
        // 更新池余额，更新_K，发生转账后马上更新
        // 交易无需更新流动性和权益性证明
        refresh();
        // 返回池余额，即本合约在对应ft余额
        amountA = poolAmount(tokenA);
        amountB = poolAmount(tokenB);
        return (amountA, amountB);
    }

    // 计算当前用确切数量的tokenA交易得到tokenB的数量
    function calculateExactAForB(uint256 _a) public view returns(uint256 _b) {
        require(_a != 0, "invalid value");
        require(get_k() != 0, "k=0");
        require(poolAmount(tokenA) + calculateFee(_a) != 0, "Math error");
        uint256 calculatedB = get_k() / (poolAmount(tokenA) + calculateFee(_a));
        return poolAmount(tokenA) - calculatedB;
    }
    // 计算当前用确切数量的tokenB交易得到tokenA的数量
    function calculateExactBForA(uint256 _b) public view returns(uint256 _a) {
        require(_b != 0, "invalid value");
        require(get_k() != 0, "k=0");
        require(poolAmount(tokenB) + calculateFee(_b) != 0, "Math error");
        uint256 calculatedA = get_k() / (poolAmount(tokenB) + calculateFee(_b));
        return poolAmount(tokenB) - calculatedA;
    }

    // 快捷查询池余额
    function poolOfA()public view returns(uint256) {
        return FT(tokenA).balanceOf(address(this));
    }
    function poolOfB()public view returns(uint256) {
        return FT(tokenB).balanceOf(address(this));
    }

    // 调用只读函数
    // allowance
    function A_allowance(address _owner, address _spender) public view returns(uint256) {
        return FT(tokenA).allowance(_owner, _spender);
    }
    function B_allowance(address _owner, address _spender) public view returns(uint256) {
        return FT(tokenB).allowance(_owner, _spender);
    }
    // balanceOf
    function A_balance(address _account) public view returns(uint256) {
        return FT(tokenA).balanceOf(_account);
    }
    function B_balance(address _account) public view returns(uint256) {
        return FT(tokenB).balanceOf(_account);
    }
    // decimals
    function A_decimals() public view returns(uint8) {
        return FT(tokenA).decimals();
    }
    function B_decimals() public view returns(uint8) {
        return FT(tokenB).decimals();
    }
    // name
    function A_name() public view returns(string memory) {
        return FT(tokenA).name();
    }
    function B_name() public view returns(string memory) {
        return FT(tokenB).name();
    }
    // owner
    function A_owner() public view returns(address) {
        return FT(tokenA).owner();
    }
    function B_owner() public view returns(address) {
        return FT(tokenB).owner();
    }
    // paused
    function A_paused() public view returns(bool) {
        return FT(tokenA).paused();
    }
    function B_paused() public view returns(bool) {
        return FT(tokenB).paused();
    }
    // symbol
    function A_symbol() public view returns(string memory) {
        return FT(tokenA).symbol();
    }
    function B_symbol() public view returns(string memory) {
        return FT(tokenB).symbol();
    }
    // totalSupply
    function A_totalSupply() public view returns(uint256) {
        return FT(tokenA).totalSupply();
    }
    function B_totalSupply() public view returns(uint256) {
        return FT(tokenB).totalSupply();
    }

    // // 调用状态修改函数
    // // delegatecall只会修改本合约的状态变量，不会作用在ft合约上，即实际无法修改tokenA和tokenB的_allowance，只能手动approve
    // function A_approve(address _spender, uint256 _amount) public returns(bool) {
    //     (bool success,) = tokenA.delegatecall(abi.encodeWithSignature("approve(address,uint256)", _spender, _amount));
    //     require(success, "A_approve call not success");
    //     return true;
    // }
    // function B_approve(address _spender, uint256 _amount) public returns(bool) {
    //     (bool success,) = tokenB.delegatecall(abi.encodeWithSignature("approve(address,uint256)", _spender, _amount));
    //     require(success, "B_approve call not success");
    //     return true;
    // }
    
}