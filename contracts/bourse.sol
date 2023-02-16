// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";

library Math {
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
}

/// @title 简单实现uniswap功能
/// @author DaiShanlang
/// @notice dapp实验二
/// @dev ## 实验内容
///      ### 1. 增加/移出流动性                      
///      ### 2. 交易功能                            
///      ### 3. 实现手续费功能，千分之三手续费          
///      ### 4. 实现滑点功能                         
///      ### 5. 实现部署脚本                         
///      ## 加分项
///      ### 2. 实现LPtoken的质押挖矿功能（流动性挖矿），需要自己做市场上产品功能调研然后实现
contract FTPair{
    
    //管理员地址，也就是部署该合约的地址和手续费收取地址
    address admin;

    FT public token1;
    FT public token2;
    FT public LPtoken;
    uint256 token1AMount;
    uint256 token2AMount;
    uint256 ratio;
    uint256 public liquidity;

    //由于solidity不支持浮点运算，在后面的比例一直按大的除以小的，该变量用于判断哪边大（默认左边大）
    bool private bigLeft;

    mapping(address => uint256) public userToken;
    
    //质押挖矿变量
    mapping(address => uint256) public timestamp;
    mapping(address => uint256) public minerToken;

    constructor(FT _LPtoken, FT _token1, FT _token2) {
        admin = msg.sender;
        token1 = _token1;
        token2 = _token2;
        LPtoken = _LPtoken;
    }

    //初始化交易池，注入流动性（按照价格进行对应比例注入，比如流动性为10:400，token2价格为40token1/token2）
    function _start(uint256 _token1AMount, uint256 _token2AMount) public payable {
        require(msg.sender == admin, "You do not have permission to call the function!");
        token1AMount = _token1AMount;
        token2AMount = _token2AMount;
        liquidity = token1AMount * token2AMount;
        if(_token1AMount > _token2AMount){
            ratio = _token1AMount / token2AMount;
            bigLeft = true;
        }else{
            ratio = _token2AMount / token1AMount;
            bigLeft = false;
        }
        token1.transferFrom(msg.sender, address(this), _token1AMount);
        token2.transferFrom(msg.sender, address(this), _token2AMount);
    }

    //增加流动性(需要按比例存入)
    function increaseLiquidity(uint256 _token1AMount, uint256 _token2AMount) public payable returns(uint256){
        require(_token1AMount > 0 && _token2AMount > 0, "The deposited money cannot be empty!");
        
        token1AMount += _token1AMount;
        token2AMount += _token2AMount;
        liquidity = token1AMount * token2AMount;

        uint256 userTotal = _token1AMount * _token2AMount;
        userToken[msg.sender] += Math.sqrt(userTotal);

        token1.transferFrom(msg.sender, address(this), _token1AMount);
        token2.transferFrom(msg.sender, address(this), _token2AMount);

        LPtoken.transfer(msg.sender, Math.sqrt(userTotal));
        return Math.sqrt(userTotal);
    }

    //移出流动性
    function removalLiquidity(uint256 _LPtoken) public payable{
        require(_LPtoken > 0, "The deposited money cannot be empty!");
        require(userToken[msg.sender] > 0, "You are not providing liquidity!");

        uint256 _token1AMount;
        uint256 _token2AMount;
        if(bigLeft == true){
            _token2AMount = _LPtoken / (Math.sqrt(ratio));
            _token1AMount = _token2AMount * ratio; 
        }else{
            _token1AMount = _LPtoken / (Math.sqrt(ratio));
            _token2AMount = _token1AMount * ratio; 
        }

        token1AMount -= _token1AMount;
        token2AMount -= _token2AMount;
        liquidity = token1AMount * token2AMount;

        userToken[msg.sender] -= _LPtoken;

        LPtoken.transferFrom(msg.sender, address(this), _LPtoken);

        token1.transfer(msg.sender, _token1AMount);
        token2.transfer(msg.sender, _token2AMount);
    }

    //交易功能+滑点(token1换token2)
    function tradeByToken1(uint256 _token1AMount) public payable returns(uint256){
        uint256 _token2AMount;
        if(bigLeft == true){
            _token2AMount = _token1AMount / ratio;
        }else{
            _token2AMount = _token1AMount * ratio;
        }

        require(_token2AMount < token2.balanceOf(address(this)), "Tokens are not enough!");
        //手续费
        uint256 premium = _token2AMount * 3 / 1000;
        
        token1AMount += _token1AMount;
        token2AMount -= _token2AMount;

        liquidity = token1AMount * token2AMount;

        token1.transferFrom(msg.sender, address(this), _token1AMount);
        token2.transfer(msg.sender, _token2AMount - premium);
        token2.transfer(admin, premium);
        return _token2AMount - premium;
    }

    //交易功能+滑点(token2换token1)
    function tradeByToken2(uint256 _token2AMount) public payable returns(uint256){
        uint256 _token1AMount;
        if(bigLeft == true){
            _token1AMount = _token2AMount * ratio;
        }else{
            _token1AMount = _token2AMount / ratio;
        }

        require(_token1AMount < token1.balanceOf(address(this)), "Tokens are not enough!");
        //手续费
        uint256 premium = _token1AMount * 3 / 1000;
        
        token1AMount -= _token1AMount;
        token2AMount += _token2AMount;

        liquidity = token1AMount * token2AMount;

        token2.transferFrom(msg.sender, address(this), _token2AMount);
        token1.transfer(msg.sender, _token1AMount - premium);
        token1.transfer(admin, premium);
        return _token1AMount - premium;
    }

    //质押挖矿功能（流动性挖矿）每个用户在矿池中只能质押一种代币，未取出前不能再次质押
    //token1质押挖矿
    function stakeByToken1(uint256 _token1AMount) public payable {
        require(_token1AMount > 0, "Staked tokens cannot be less than zero!");
        uint256 _startWord;
        if(bigLeft == true){
            _startWord = _token1AMount / (Math.sqrt(ratio));
        }else{
            _startWord = _token1AMount * (Math.sqrt(ratio));
        }

        minerToken[msg.sender] = _startWord;
        timestamp[msg.sender] = block.number;

        token1AMount += _token1AMount;
        liquidity = token1AMount * token2AMount;
        token1.transferFrom(msg.sender, address(this), _token1AMount);
    }

    //取出质押token1和挖矿奖励
    function unstackByToken1() public payable returns(uint256) {
        uint256 _startWord = minerToken[msg.sender];
        uint256 _oldBlockNumber = timestamp[msg.sender];
        require(_startWord > 0 && _oldBlockNumber > 0, "You are not staking tokens!");
        uint256 _token1AMount;

        if(bigLeft == true){
            _token1AMount = _startWord * (Math.sqrt(ratio));
        }else{
            _token1AMount = _startWord / (Math.sqrt(ratio));
        }

        //自定义的挖矿奖励公式
        uint256 reward = _startWord * (block.number - _oldBlockNumber) / 1000;

        //维护变量
        delete minerToken[msg.sender];
        delete timestamp[msg.sender];

        token1AMount -= _token1AMount;
        liquidity = token1AMount * token2AMount;

        token1.transfer(msg.sender, _token1AMount);
        LPtoken.transfer(msg.sender, reward);

        return reward;
    }

    //token2质押挖矿
    function stakeByToken2(uint256 _token2AMount) public payable {
        require(_token2AMount > 0, "Staked tokens cannot be less than zero!");
        uint256 _startWord;
        if(bigLeft == true){
            _startWord = _token2AMount * (Math.sqrt(ratio));
        }else{
            _startWord = _token2AMount / (Math.sqrt(ratio));
        }

        minerToken[msg.sender] = _startWord;
        timestamp[msg.sender] = block.number;

        token2AMount += _token2AMount;
        liquidity = token1AMount * token2AMount;
        token2.transferFrom(msg.sender, address(this), _token2AMount);
    }

    //取出质押token2和挖矿奖励
    function unstackByToken2() public payable returns(uint256) {
        uint256 _startWord = minerToken[msg.sender];
        uint256 _oldBlockNumber = timestamp[msg.sender];
        require(_startWord > 0 && _oldBlockNumber > 0, "You are not staking tokens!");
        uint256 _token2AMount;

        if(bigLeft == true){
            _token2AMount = _startWord / (Math.sqrt(ratio));
        }else{
            _token2AMount = _startWord * (Math.sqrt(ratio));
        }

        //自定义的挖矿奖励公式
        uint256 reward = _startWord * (block.number - _oldBlockNumber) / 1000;

        //维护变量
        delete minerToken[msg.sender];
        delete timestamp[msg.sender];

        token2AMount -= _token2AMount;
        liquidity = token1AMount * token2AMount;

        token2.transfer(msg.sender, _token2AMount);
        LPtoken.transfer(msg.sender, reward);

        return reward;
    }
}