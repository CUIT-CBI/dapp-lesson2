pragma solidity ^0.8.0;

import "./FT.sol";
import "./Math.sol";

contract swap {
    address public owner;

    //两个代币的地址
    address public token_1;
    address public token_2;

    //代币总量
    uint256 public token_1Amount;
    uint256 public token_2Amount;

    uint256 public sign = 0;
    uint public  liquidity;

    constructor(address _token_1, address _token_2)ERC20("LiquidityProvider", "LP") {        
        token_1 = _token_1;
        token_2 = _token_2;
        owner = msg.sender;
    }

    function _updateReserves() public {
        token_1Amount = ERC20(token_1).balanceOf(address(this));
        token_2Amount = ERC20(token_2).balanceOf(address(this));
    }

    function init(uint256 token_1Amount, uint256 token_2Amount) public payable {
        require (owner == msg.sender);
        require(sign == 0);
        sign = 1;
        token_1Amount = token_1Amount;
        token_2Amount = token_2Amount;
        ERC20(token_1).transferFrom(msg.sender, address(this), token_1Amount);
        ERC20(token_2).transferFrom(msg.sender, address(this), token_2Amount);

        uint initLiquidity = sqrt(_amount0 * _amount1);
        _mint(msg.sender, initLiquidity);
    }
    modifier Inited {
        require(sign == 1,"You should init");
        _;
    }

    // 增加流动性
     function addLiquidity(address _token, uint256 _amount)external Inited {
        require(_token == token_1 || _token == token_2,"Invalid address");
        uint amount1;
        uint amount2;
       
        if(_token == token_1){
            amount1 = _amount;

            amount2 = token_2Amount * amount1 / token_1Amount;            
        } else {
            amount2 = _amount;

            amount1 = token_1Amount * amount2 / token_2Amount;
        }

        ERC20(token0).transferFrom(msg.sender, address(this), amount1);
        ERC20(token1).transferFrom(msg.sender, address(this), amount2);


        liquidity = min(totalSupply() * amount1 / token_1Amount, totalSupply() * amount2 / token_2Amount);

        _mint(msg.sender, liquidity);

        _updateReserves();
        
        return liquidity;
    }
     // 移除流动性
    function removeLiquidity(uint256 _liquidity)external payable Initedreturns (uint256, uint256) {
        require(_liquidity > 0 );

        uint256 balance1 = ERC20(token_1).balanceOf(address(this));
        uint256 balance2 = ERC20(token_2).balanceOf(address(this));

        amount1 = _liquidity * balance1 / totalSupply();       
        amount2 = _liquidity * balance2 / totalSupply();

        //销毁LP代币
        _burn(msg.sender, _liquidity);

        ERC20(token_1).transfer(msg.sender, amount1);
        ERC20(token_2).transfer(msg.sender, amount2);

        _updateReserves();

        return (amount1, amount2);
    }


    //交易
    function swapToken1(uint256 SwapToken1Amount)external payable Inited returns (uint256 getToken2Amount) {
        ERC20(token_1).transferFrom(msg.sender, address(this), SwapToken1Amount);
        getToken2Amount = (token_2Amount - (token_1Amount * token_2Amount) / (token_1Amount + SwapToken_1Amount))  * 997 / 1000;
        ERC20(token_2).transfer(msg.sender, getToken2Amount);
        _updateReserves();
    }

    function swapToken2(uint256 SwapToken2Amount)external payable Inited returns (uint256 getToken1Amount) {
        ERC20(token_2).transferFrom(msg.sender, address(this), SwapToken2Amount);
        // 千分之三手续费
        getToken1Amount = (token_1Amount - (token_2Amount * token_1Amount) / (token_2Amount + SwapToken2Amount))  * 997 / 1000;   
        ERC20(token_1).transfer(msg.sender, getToken1Amount);
        _updateReserves();
    }

    
    function SwapUnderslip(address _token, uint256 _inputAmount, uint256 _minTokens) external returns (uint256) {
        require(_token == token_1 || _token == token_2);
        uint256 expectGetAmount;
        uint256 actualGetAmount;
        //滑点
        uint256 slipPoint = 6;
        if(_token == token_1){
            expectGetAmount = token_2Amount * _inputAmount / token_1Amount;
            actualGetAmount = swapToken1(_inputAmount, _minTokens);
        }
        if(_token == token_1){
            expectGetAmount =  token_1Amount * _inputAmount /token_2Amount;
            actualGetAmount = swapToken2(_inputAmount, _minTokens);
        }
        uint256 slip = (expectGetAmount - actualGetAmount) * 1000 / expectGetAmount;

        require(slip <= slipPoint);

        _updateReserves();
    }
   
}