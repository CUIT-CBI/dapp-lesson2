pragma solidity ^0.8.0;

contract LPMining {
    mapping(address => uint256) public stakedBalance;//用户的质押余额
    mapping(address => mapping(address => uint256)) public allowance;//授权的金额。
    mapping(address => uint256) public rewards;//奖励余额
    address public owner;//合约的 owner 地址
    event Deposit(address indexed _from, uint256 _value);//当用户向合约存款时
    event Reward(address indexed _to, uint256 _value);//当用户领取奖励时

    constructor() public {
        owner = msg.sender;
    }

    function deposit() public payable {//存款
        require(msg.value > 0, "Deposit value must be greater than zero");
        stakedBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _value) public {//提款
        require(stakedBalance[msg.sender] >= _value, "Insufficient staked balance");
        require(_value > 0, "Withdrawal value must be greater than zero");
        address(msg.sender).transfer(_value);
        stakedBalance[msg.sender] -= _value;
        //emit Withdrawal(msg.sender, _value);
    }

    function approve(address _spender, uint256 _value) public {
        require(_spender != address(0), "Spender address cannot be null");
        require(_value > 0, "Approval value must be greater than zero");
        allowance[msg.sender][_spender] = _value;
    }

    function claimReward() public {//用户领取其奖励余额。
        require(rewards[msg.sender] > 0, "No rewards to claim");
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        msg.sender.transfer(reward);
        emit Reward(msg.sender, reward);
    }

    //distributeReward()由合约的 owner 调用，用来根据质押金额给用户分发奖励。
    //它遍历所有用户的质押余额，并将 1% 的奖励分配给每个用户。
     function distributeReward() public onlyOwner {//根据质押金额给用户分发奖励
         address[] memory users = address[] (stakedBalance);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            rewards[user] += stakedBalance[user] * 0.01; // 1% reward for staked balance
        }
    }

     //这个修饰器用于限制只有合约的 owner 才能调用特定的函数。
    //这里限制了 distributeReward 函数只能由 owner 来调用。
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
       
    }
}
