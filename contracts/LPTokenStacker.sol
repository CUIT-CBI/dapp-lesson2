// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20.sol";

// 包装LPToken
contract LPTokenWrapper {
    using SafeMath for uint256;
    IERC20 public _lpt;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // 防止重入 如果lpt是别人的。这里lpt是自己的，不存在重入问题。
    function stake(uint256 amount) public virtual lock {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _lpt.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _lpt.transfer(msg.sender, amount);
    }
}

// 分红按比例分红
contract LPTokenStacker is LPTokenWrapper, Ownable {
    using SafeMath for uint256;
    IERC20 public _rewardToken;
    uint256 public constant DURATION = 1 days; // 质押周期

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored; // 每个token得奖励
    mapping(address => uint256) public userRewardPerTokenPaid; // 每个用户支付的奖励
    mapping(address => uint256) public rewards; //总奖励

    // 快照
    struct Boardseat {
        uint256 lastSnapshotIndex; //最后一次下标
        uint256 rewardEarned;
    }

    // 奖励的快照
    struct BoardSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    // 操作者的合约
    mapping(address => bool) public operators;

    mapping(address => Boardseat) private directors;

    // 分红下表的数组
    BoardSnapshot[] private boardHistory;

    // lpt,奖励的token 奖励单个lpt，发单一TOKEN，uniswap对应多个TOKEN。
    constructor(address lpt,address rewardToken) {
        _lpt = IERC20(lpt);
        _rewardToken = IERC20(rewardToken);

        BoardSnapshot memory genesissSnapshot = BoardSnapshot({
        time: block.number,
        rewardReceived: 0,
        rewardPerShare: 0
        });
        operators[msg.sender] = true;
        boardHistory.push(genesissSnapshot);
    }

    modifier onlyOperator() {
        require(operators[msg.sender],'not allow to this');
        _;
    }

    // 更新余额
    modifier updateReward(address director) {
        // 只是更新能够领取
        if(director != address(0) ) {
            Boardseat memory seat = directors[director];
            seat.rewardEarned = earned(director); // 当前用户能够领取
            seat.lastSnapshotIndex = latestSnapshotIndex();
            directors[director] = seat;
        }
        _;
    }

    function setOperator(address[] memory operatorList, bool flag) public onlyOwner {
        for(uint256 i=0;i<operatorList.length;i++) {
            operators[operatorList[i]] = flag;
        }
    }

    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0,'Cannot stake 0');
        super.stake(amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount>0,'Cannot withdraw 0');
        super.withdraw(amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = directors[msg.sender].rewardEarned;
        if(reward > 0) {
            directors[msg.sender].rewardEarned = 0;
            _rewardToken.transfer(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    // 获取快照的行数
    function latestSnapshotIndex() public view returns(uint256) {
        return boardHistory.length.sub(1);
    }

    // 获取最后一个快照
    function getLatestSnapshot() internal view returns(BoardSnapshot memory) {
        return boardHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address director) public view returns (uint256) {
        return directors[director].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address director) public view returns (BoardSnapshot memory) {
        return boardHistory[getLastSnapshotIndexOf(director)];
    }

    function rewardPerShare() public view returns(uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    // 获取某一个地址该获取的奖励 比例分红 LP的余额 * (总的RPS - 个人的RPS) * 1e18 + 已经领取的 - 已经领的
    function earned(address director) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(director).rewardPerShare;
        uint256 rewardEarned = balanceOf(director)
        .mul(latestRPS.sub(storedRPS)).div(1e18)
        .add(directors[director].rewardEarned);
        return rewardEarned;
    }

    function addNewSnapshot(uint256 amount) private {
        uint256 preRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = preRPS.add(amount.mul(1e18).div(totalSupply()));
        BoardSnapshot memory newSnapshot = BoardSnapshot({
        time: block.number,
        rewardReceived: amount,
        rewardPerShare: nextRPS
        });
        boardHistory.push(newSnapshot);
    }

    function allocateWithToken(uint256 amount) external {
        require(amount > 0, 'Cannot allocate 0');
        if(totalSupply() > 0 ) {
            addNewSnapshot(amount);
            if(amount>0) _rewardToken.transferFrom(msg.sender,address(this),amount);
        }
    }

    // 给每一个代币分红多沙坡 记录
    function allocate(uint256 amount) external onlyOperator{
        require(amount > 0,'Cannot allocate 0');
        addNewSnapshot(amount);
    }

    // 审计的时候用
    function withdrawForeignTokens(address token,address to,uint256 amount) onlyOwner public returns (bool) {
        return IERC20(token).transfer(to,amount);
    }
}
