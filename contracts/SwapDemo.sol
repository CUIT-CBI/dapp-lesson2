pragma solidity ^0.8.0;

import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/** 完成以下内容
### 1. 增加/移出流动性                      30分
### 2. 交易功能                            30分
### 3. 实现手续费功能，千分之三手续费        10分
### 4. 实现滑点功能                         15分


*/
contract SwapDemo is FT{
    // 新建两个代币
    address public uno_token;
    address public dos_token;
    // 存储代币数量
    uint public uno_balance;
    uint public dos_balance;
    constructor(address _uno_token, address _dos_token) FT("EAtoken", "EA"){
        uno_token = IERC20(_uno_token);
        dos_token = IERC20(_dos_token);
    }
    // 增加流动性
    function addLiquidity(uint uno_amount, uint dos_amount) external returns (uint liquidity) {
        uno_token.transferFrom(msg.sender, address(this), uno_amount);
        dos_token.transferFrom(msg.sender, address(this), dos_amount);

        uint _totalSupply = totalSupply();
        liquidity = Math.min(uno_amount * _totalSupply / uno_balance, dos_amount * _totalSupply / dos_balance);
        require(liquidity > 0, "add error");
            _mint(msg.sender, liquidity);
            // 更新代币数量
            uno_balance += uno_amount;
            dos_balance += dos_amount;
        }           
        // 移除流动性
    function removeLiquidity(uint liquidity) external {
        require(liquidity > 0 && liquidity <= balanceOf(msg.sender), "amount error");
        uint amountA = liquidity * uno_balance / totalSupply();
        uint amountB = liquidity * dos_balance / totalSupply();
        _burn(msg.sender, liquidity);
        // 更新代币数量
        uno_token.transfer(msg.sender, amountA);
        dos_token.transfer(msg.sender, amountB);

        uno_balance =uno_token.balanceOf(address(this));
        dos_balance = dos_token.balanceOf(address(this));
    }






    // 实现交易、滑点和手续费 (千分之三)
    function unoswapdos(uint _min, uint _amountA) external {
        uint amount =  (dos_amount - uno_amount * dos_amount / (uno_amount + amountA))  * 997/1000;
        require(_amountA >= _min, "error: less");
        uno_token.transferFrom(msg.sender, address(this), amountA);
        dos_token.transfer(msg.sender, amountB);
        uint targetAmountB = dos_amount * amountA / uno_amount;
        slippage = (targetAmountB - amountB) * 100 / targetAmountB;
        uno_balance += amount;
        dos_balance -= amount;
    }

     function dosswapuno(uint _min, uint _amountA) external {
        uint amountA =  (uno_amount - dos_amount * uno_amount / (dos_amount + amountB))  * 997/1000;
        require(_amountB >= _min, "error: less");
        dos_token.transferFrom(msg.sender, address(this), amountB);
        uno_token.transfer(msg.sender, amountA);
        uint targetAmountA = uno_amount * _amountB / dos_amount;
        slippage = (targetAmountA - amountA) * 100 / targetAmountA;
        uno_balance += amount;
        dos_balance -= amount;
    }
}