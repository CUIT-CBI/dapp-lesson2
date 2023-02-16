pragma solidity >=0.5.0;

import "../core/GzxERC20.sol";
import "../core/interfaces/IGzxERC20.sol";
import "./libraries/Ownable.sol";

contract StakerMain is Ownable{
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;     // 用户提供了多少 LP 代币。
        uint256 rewardDebt; // 奖励债务
    }


    //每一个矿池的数据结构
    struct PoolInfo {
        IGzxERC20 lpToken;     // contract.uniswap的令牌地址
        uint256 allocPoint;       // 分配给这个池的分配点数
        uint256 lastRewardBlock;  // 分配发生的最后一个块号
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.sushi的配额
    }



    GzxERC20 public stakerPool;
    //管理员地址
    address public admin;

    uint256 public bonusEndBlock;

    uint256 public stakerPerBlock;
    // 奖金乘数
    uint256 public constant BONUS_MULTIPLIER = 2;

    //矿池注册
    PoolInfo[] public poolInfo;

    //用户令牌
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        GzxERC20 _stakerPool,
        address _devaddr,
        uint256 _stakerPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        stakerPool = _stakerPool;
        admin = _devaddr;
        stakerPerBlock = _stakerPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    //增加矿池，管理员权限
    function add(uint256 _allocPoint, IGzxERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSushiPerShare: 0
        }));
    }


    //设置矿池参数，管理员权限
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }



    //获得参数信息
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }


    //获得矿池信息
    function pendingStaker(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 stakerReward = multiplier.mul(stakerPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSushiPerShare = accSushiPerShare.add(stakerReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    //更新所有矿池信息
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    //更新某个矿池信息
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 stakerReward = multiplier.mul(stakerPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        // 计算出的奖励以 20% 分配给开发地址，另外 80% 分配给池 LP 质押者。
        stakerPool.mint(admin, stakerReward.div(20));
        stakerPool.mint(address(this), stakerReward);
        pool.accSushiPerShare = pool.accSushiPerShare.add(stakerReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    //存入LP
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
            safeStakerTransfer(msg.sender, pending);
        }
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    //撤出LP
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
        safeStakerTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        pool.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    //无条件撤出令牌，用于矿池出现严重问题的时候
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function safeStakerTransfer(address _to, uint256 _amount) internal {
        uint256 stakerBal = stakerPool.balanceOf(address(this));
        if (_amount > stakerBal) {
            stakerPool.transfer(_to, stakerBal);
        } else {
            stakerPool.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    //设置管理员信息
    function dev(address _devaddr) public {
        require(msg.sender == admin, "dev: wut?");
        admin = _devaddr;
    }
}
