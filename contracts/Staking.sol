pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FT.sol";

contract Staking {
   
    ERC20 public stakToken;
    FT public rewordToken;
    
    
    //最近一次挖矿区块数的更新
    uint256 public LastBlocktime;
    //该合约质押币的总量
    uint256 private _totalSupply;
    //每分钟区块奖励的数量
    uint256 public RewordPerMin = 100;
    //用户的质押信息
    mapping(address => Info ) public userInfo;
    //用户累计奖励余额
    mapping(address => uint256) rewords;
    mapping(address => bool) users;
    //存放每个用户得挖矿数
    uint[] public BlockNumbers;

    struct Info{
        uint256 balances;
        uint256 StartBlock;
        uint256 EndBlock; 
    }

    constructor(address _stakToken,address _rewordToken, uint256 _RewordPerMin) public{
        stakToken = ERC20(_stakToken);
        rewordToken = FT(_rewordToken);
        RewordPerMin = _RewordPerMin;
    }

    modifier onlyOwner() {
        require(users[msg.sender] == true);
        _;

    }
    //设置质押的地址
    function setUser(address account) public returns(bool){
        users[account] = true;
    }

    //质押挖矿
    function stake(uint256 amount) external onlyOwner(){
        require(amount > 0, "Cannot stake 0");
        require(msg.sender != address(0));
        Info memory user = userInfo[msg.sender];
        //记录挖矿开始区块数
        user.StartBlock = block.number;
        user.balances += amount;
        _totalSupply +=  amount ;
        stakToken.transferFrom(msg.sender, address(this), amount);
    }

    //取出质押金
    function Unstake(uint256 amount) external onlyOwner() {
        require(amount > 0,"Cannot stake more");
        Info memory user = userInfo[msg.sender];
        user.EndBlock = block.number;
        uint256 blockNumber = user.EndBlock - user.StartBlock;
        //将每个质押用户产生的区块存入数组
        BlockNumbers.push(blockNumber);
        user.balances -= amount;
        _totalSupply -= amount ;
        stakToken.transfer(msg.sender, amount);
    }

    //更新用户余额
    function _updateReword() public onlyOwner(){
        Info memory user = userInfo[msg.sender];
        //计算所有用户挖矿的总区块数
        uint256 total;
        for(uint256 i=0;i<BlockNumbers.length-1;i++){
            total += BlockNumbers[i];
        }
        //该用户占总奖励的比例
        uint reward = user.balances * (total * 100) / _totalSupply;
        rewords[msg.sender] += reward;
    }

    //用户提取
    function getReword() internal {
        uint256 reword = rewords[msg.sender];
        if(reword > 0){
            //防止重复提取奖励
            rewords[msg.sender] = 0;
            rewordToken.mint(msg.sender,reword);
        }
    }

}
