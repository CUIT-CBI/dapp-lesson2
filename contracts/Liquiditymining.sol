// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./FT.sol";

library Math {
    function min(uint x, uint y) external pure returns (uint z) {
        z = x < y ? x : y;
    }
    function sqrt(uint y) external pure returns (uint z) {
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

contract Liquiditymining {
    address public token1;
    address public token2;
    uint256 token1Balance;
    uint256 token2Balance;
    uint256 public totalLiquidity;
    mapping(address => uint256) public LPtoken;
    FT public rewardToken;

    //质押的信息
    struct userInfo{
        uint256 amount;
        uint256 stakeTime;
        uint256 startTime;
    }
    mapping(address => userInfo) public details;
    constructor(address _token1, address _token2, uint256 token1In, uint256 token2In, FT _rewardToken) {
        token1 = _token1;
        token2 = _token2;
        token1Balance += token1In;
        token2Balance += token2In;
        rewardToken = _rewardToken;
        totalLiquidity = Math.sqrt(token1In * token2In);
    }
    //转账
    function tokenDivTransfer(address _tokenA,address _tokenB,uint256 amountIn,uint256 rate)internal{
        require(
                FT(_tokenA).transferFrom(msg.sender, address(this), amountIn) &&
                    FT(_tokenB).transferFrom(
                        msg.sender,
                        address(this),
                        amountIn / rate
                    )
            );
            if(_tokenA==token1) {
                LPtoken[msg.sender] += amountIn * totalLiquidity / token1Balance;
                totalLiquidity+=LPtoken[msg.sender];
                token1Balance += amountIn;
                token2Balance += amountIn / rate;
            }else {
                LPtoken[msg.sender] += amountIn * totalLiquidity / token2Balance;
                totalLiquidity += LPtoken[msg.sender];
                token2Balance += amountIn;
                token1Balance += amountIn / rate;
            }

    }
    function TokenMulTransfer(address _tokenA,address _tokenB,uint256 amountIn,uint256 rate) internal {
        require(
                FT(_tokenA).transferFrom(msg.sender, address(this), amountIn) &&
                    FT(_tokenB).transferFrom(
                        msg.sender,
                        address(this),
                        amountIn * rate
                    )
            );
            if(_tokenA==token1) {
                LPtoken[msg.sender] += amountIn * totalLiquidity / token1Balance;
                totalLiquidity += LPtoken[msg.sender];
                token1Balance += amountIn;
                token2Balance += amountIn * rate;
            }else {
                LPtoken[msg.sender] += amountIn * totalLiquidity / token2Balance;
                totalLiquidity += LPtoken[msg.sender];
                token2Balance += amountIn;
                token1Balance += amountIn * rate;
            }
    }
    
    //质押挖矿功能
    function _Liquiditymining(uint256 blocknumber) public {
        userInfo storage user = details[msg.sender];
        user.startTime = block.number;
        user.stakeTime = blocknumber;
        user.amount += LPtoken[msg.sender];
        LPtoken[msg.sender]=0;
    }
    //取质押token和获得奖励代币
    function unstake()public{
        userInfo storage user = details[msg.sender];
        require(block.number > user.startTime + user.stakeTime);
        uint256 amount = user.amount;
        uint256 stakeTime = user.stakeTime;
        rewardToken.mint(msg.sender, stakeTime * amount);
        LPtoken[msg.sender]=amount;
    }

}
