// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";

contract pool{
    address token1;
    address token2;
    uint256 amount1;
    uint256 amount2;
    uint256 balance1;
    uint256 balance2;
    uint256 price1;
    uint256 price2;
    uint256 liq;
    
    function sqrt(uint a) internal pure returns (uint x) {
        if (a > 3) {
            x = a;
            uint temp = a / 2 + 1;
            while (temp < x) {
                x = temp;
                temp = (a / temp*2) / 2;
            }
        } else if (a != 0) {
            x = 1;
        }
    }
    
    //创建交易池
    function createPool(address _token1, address _token2, uint256 num1, uint256 num2) public{
        require(_token1 == token1 && _token2 == token2, 'without this token');
        FT(token1).transferFrom(msg.sender, address(this), num1);
        FT(token2).transferFrom(msg.sender, address(this), num2);
        amount1 = num1;
        amount2 = num2;
        balance1 = FT(token1).balanceOf(address(this));
        balance2 = FT(token2).balanceOf(address(this));

        liq = sqrt(amount1*amount2);
        
    }    
    
    function min(uint256 x, uint256 y) public pure returns(uint256){
        if(x >= y ){
            return y;
        }else{
            return x;
        }
    }

    //增加流动性
    function addLiq(address _token1, address _token2, uint256 _number1, uint _number2) public returns(uint256){
        require(_token1 == token1 && _token2 == token2, 'without this token');
        require(_number1 != 0 && _number2 != 0, 'ERROR input');

        FT(token1).transferFrom(msg.sender, address(this), _number1);
        amount1 += _number1;
        balance2 = FT(token2).balanceOf(address(this));
        amount2 = balance2 * amount1 / balance1;  // amount1/balance1 = amount2/balance2

        FT(token2).transferFrom(msg.sender, address(this), _number2);
        amount2 += _number2;
        balance1 = FT(token1).balanceOf(address(this));
        amount1 = balance1 * amount2 /balance2;
        
        balance1 = FT(token1).balanceOf(address(this));
        balance2 = FT(token2).balanceOf(address(this));

        liq = min(FT(token1).totalSupply() * amount1 / balance1, FT(token2).totalSupply() * amount2 / balance2); // liquidity / totalSupply = amount / balance
        return liq;
    }

    //移出流动性
    function removeLiq(address _token1, address _token2, uint256 _number1, uint _number2) public returns(uint256){
        require(_token1 == token1 && _token2 == token2, 'without this token');
        require(_number1 != 0 && _number2 != 0, 'ERROR input');

        FT(token1).transferFrom(address(this), msg.sender, _number1);
        amount1 -= _number1;
        balance2 = FT(token2).balanceOf(address(this));
        amount2 = balance2 * amount1 / balance1;  // amount1/balance1 = amount2/balance2

        FT(token2).transferFrom(address(this), msg.sender, _number2);
        amount2 += _number2;
        balance1 = FT(token1).balanceOf(address(this));
        amount1 = balance1 * amount2 /balance2;
        
        balance1 = FT(token1).balanceOf(address(this));
        balance2 = FT(token2).balanceOf(address(this));

        liq = min(FT(token1).totalSupply() * amount1 / balance1, FT(token2).totalSupply() * amount2 / balance2); // liquidity / totalSupply = amount / balance
        return liq;
    }

    //手续费交易功能
    function fee(uint256 money)public pure returns(uint256 bala) {
        bala = money * 997 / 1000;
        return bala;
    }

    function tokenExchange(address _token, uint256 _number) public returns(bool){
        require(_token == token1 || _token == token2, 'without this token');
        require(_number != 0, 'ERROR input');
        require(slipPoint(_token, _number) == true, 'out range of slipPoint'); //检验滑点范围
        uint256 ride = amount1 *amount2;
        if (_token == token1){
            require(_number <= FT(_token).balanceOf(msg.sender)/price1, 'your balance is not enough');
            FT(token1).transferFrom(msg.sender, address(this), fee(_number));
            amount1 += _number;
            FT(token2).transferFrom(address(this), msg.sender, fee(amount2 - (ride / amount1)));
            amount2 = ride / amount1; // amount1 * amount2 = k
        }else {
            require(_number <= FT(_token).balanceOf(msg.sender)/price2, 'your balance is not enough');
            FT(token2).transferFrom(msg.sender, address(this), fee(_number));
            amount2 += _number;
            FT(token1).transferFrom(address(this), msg.sender, fee(amount1 - (ride / amount2)));
            amount1 = ride / amount2;
        } 
        return true;
    }

    function balanceOfToken1(address add)public view returns(uint256){
        return FT(token1).balanceOf(add); 
    }
    
    function balanceOfToken2(address add)public view returns(uint256){
        return FT(token2).balanceOf(add); 
    }
     
    //滑点功能
    //实际能兑换的token数和预计兑换的token数的比值为滑点，设置滑点范围6%
    function slipPoint(address _token, uint256 _number)public view returns(bool){
        require(_token == token1 || _token == token2, 'without this token');
        require(_number != 0, 'ERROR input');
        uint256 _rate = amount1 * 1000/ amount2; 
        uint rate;
        uint256 ride = amount1 *amount2;
        if (_token == token1 ){
            uint256 _amount2_ = amount2 -  ride / amount1;
            rate = _number * 1000 / _amount2_;
        }else{
            uint256 _amount1_ = amount1 -  ride / amount1;
            rate = _amount1_ * 1000/ _number;
        }

        if ((rate * 1000 / _rate)  >= 60){
            return false;
        }else{
            return true;
        }
    }
}