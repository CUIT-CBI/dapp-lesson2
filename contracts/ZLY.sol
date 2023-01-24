// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Math.sol"
import "./FT.sol";


contract ZLY is FT{

    uint public MINIMUM_LIQUIDITY = 10**3;
   
    address public Token1;
    address public Token2;
    address Factory;
    //两种token在交易池中的储备量
    uint112 public Reserve1;
    uint112 public Reserve2;


    constructor(address _Token1, address _Token2) FT("ZLYtoken","ZLY") {
        Token1 = _Token1;
        Token2 = _Token2;
    }

    function getReserves() public view returns (uint112 _Reserve1, uint112 _Reserve2) {
        _Reserve1 = Reserve1;
        _Reserve2 = Reserve2;
    }
        //交易
    function _exchange(
        uint amount1In, 
        uint amount2In, 
        uint amountMin,
        address fromToken, 
        address toToken, 
        address to) external{
            require(to != fromToken && to != toToken, 'Ft: INVALID_TO');
            (uint112 _reserve1, uint112 _reserve2) = getReserves();
            //判断哪个是用来兑换的货币
            if(amount1In > 0) ERC20(fromToken).transferFrom(msg.sender, address(this), amount1In);
            if(amount2In > 0) ERC20(fromToken).transferFrom(msg.sender, address(this), amount2In);
            //当前交易池里面还剩下多少token  
            uint balance1 = ERC20(token1).balanceOf(address(this));
            uint balance2 = ERC20(token2).balanceOf(address(this));
            //扣除手续费
            uint amount1Out = getAmount(amount1In,_reserve1,_reserve2) * (1-0.003);
            uint amount2Out = getAmount(amount2In,_reserve2,_reserve1) * (1-0.003);

    //赋予流动性
    function addliqiudity(uint amount1, uint amount2, address to) external returns(uint liquid) {
       require(to != token1 && to != token2, 'to io wrong');
       (uint112 _reserve1, uint112 _reserve2) = getReserves();
       //将token转入交易池储存
       ERC20(token1).transferFrom(msg.sender,address(this),amount1);
       ERC20(token2).transferFrom(msg.sender,address(this),amount2);
//当前合约token的总数量
       uint256 currentSupply = super.totalSupply();
       uint256 reserveAfter1 = _reserve1 + amount1;
       uint256 reserveAfter2 = _reserve2 + amount2;

       if(currentSupply == 0 ){
           liquid = Math.sqrt(amount1 * amount2) - MINIMUM_LIQUIDITY;
           _mint(msg.sender,liquid);
       }else{
           uint liquid1 = reserveAfter1 * currentSupply / _reserve1;
           uint liquid2 = reserveAfter2 * currentSupply / _reserve2;
           liquid = Math.min(liquid1,liquid2);
        }
        super._mint(to,liquid);
        //更新交易池里代币的储备数量
        reserve1 += uint112(reserveAfter1);
        reserve2 += uint112(reserveAfter2);

    }

    //移除流动性
    function removeLiquidity(uint liquid) public returns(uint amount1, uint amount2) {
        (uint112 _Reserve1, uint112 _Reserve2) = getReserves();
        //将代表流动性质的ft代币收回
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint balance2 = ERC20(token2).balanceOf(address(this));
        transfer(address(this),liquid);
        uint currentSupply = super.totalSupply();
        //这部分ft代币在交易池中代表的token0、token1加上手续费的数量
        amount1 = liquid * _Reserve1 / currentSupply;
        amount2 = liquid * _Reserve2 / currentSupply;
        //将ft代币销毁
        super._burn(msg.sender,liquid);
        //将转入交易池的代币转回给账户
        ERC20(token1).transfer(msg.sender,amount1);
        ERC20(token2).transfer(msg.sender,amount2);

        balance1 = ERC20(token1).balanceOf(address(this));
        balance2 = ERC20(token2).balanceOf(address(this));
        //还原交易池里面原本代币储备数量
        Reserve1 = uint112(balance1);
        Reserve2 = uint112(balance2);
    }

    function getAmount(uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut) private pure returns (uint256 amountOut) {
        amountOut = (reserveIn * reserveOut) / (reserveIn + amountIn);
        return amountOut;
    }


       //设置滑点
            if(amount1Out > 0) {
                require(amount1Out >= amountMin,'no more than amountIn');
                ERC20(toToken).transferFrom(msg.sender,to,amount1Out);
            }
            if(amount2Out > 0) {
                require(amount2Out >= amountMin,'no more than amountMin');
                ERC20(toToken).transferFrom(msg.sender,to,amount1Out);
            }
            reserve1 = uint112(balance1);
            reserve2 = uint112(balance2);
        }

}
