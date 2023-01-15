// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/** 完成以下内容
### 1. 增加/移出流动性                      30分
### 2. 交易功能                            30分
### 3. 实现手续费功能，千分之三手续费        10分
### 4. 实现滑点功能                         15分
### 5. 实现部署脚本                         15分
## 加分项
### 1. 实现上述所有基础功能，并且实现自己的前端对接这个合约
*/
contract UniswapLSH is FT {
    // 新建两个代币
    address public token1;
    address public token2;
    // 存储代币数量
    uint public balance1;
    uint public balance2;


    constructor(address _token1, address _token2) FT("LSH", "Alias"){
        token1 = _token1;
        token2 = _token2;
    }


    // 增加流动性
    function addLiquidity(uint _amount1, uint _amount2) external {
        require(_amount1 != 0 && _amount2 != 0, "add error");
        uint256 liquidity;
        if (balance1 != 0) {
            uint256 count1 = (_amount2 * balance1) / balance2;
            require(_amount1 >= count1, "lack token");
            assert(IERC20(token1).transferFrom(msg.sender, address(this), count1));
            assert(IERC20(token2).transferFrom(msg.sender, address(this), _amount2));
            liquidity = (_amount1 * totalSupply()) / balance1;
            _mint(msg.sender, liquidity);
            // 更新代币数量
            balance1 += count1;
            balance2 += _amount2;
        } else {
            assert(IERC20(token1).transferFrom(msg.sender, address(this), _amount1));
            assert(IERC20(token2).transferFrom(msg.sender, address(this), _amount2));
            liquidity = _amount1;
            _mint(msg.sender, liquidity);
            // 更新代币数量
            balance1 += _amount1;
            balance2 += _amount2;
        }
    }

    // 移除流动性
    function removeLiquidity(uint _amount1) external {
        require(_amount1 > 0 && _amount1 <= (balanceOf(msg.sender) * balance1) / totalSupply(), "amount error");
        uint _amount2 = (_amount1 * balance2) / balance1;
        // 销毁
        _burn(msg.sender, _amount1);
        // 转出token
        assert(IERC20(token1).transfer(msg.sender, _amount1));
        assert(IERC20(token2).transfer(msg.sender, _amount2));
        // 更新池中代币数量
        balance1 = balance1 - _amount1;
        balance2 = balance2 - _amount2;

    }

    function getBothBalance() external view returns (uint, uint) {
        return (balance1, balance2);
    }


    // 获取数量
    function getAmount(uint _amountInput, uint _balanceInput, uint _balanceOutput) internal pure returns (uint) {
        uint amountOutput = (_balanceOutput * _amountInput) / (_balanceInput + _amountInput);
        return amountOutput;
    }


    // 实现交易、滑点和手续费
    function swapToken1ForToken2(uint _min, uint _amount) external {
        uint amount = getAmount(_amount, balance1, balance2);
        // 手续费千分之三
        amount = amount * 997 / 1000;
        require(amount >= _min, "less than min");
        assert(IERC20(token1).transferFrom(msg.sender, address(this), _amount));
        assert(IERC20(token2).transfer(msg.sender, amount));
        balance2 -= amount;
        balance1 += _amount;
    }

    // 实现交易、滑点和手续费
    function swapToken2ForToken1(uint _min, uint _amount) external {
        uint amount = getAmount(_amount, balance2, balance1);
        // 手续费千分之三
        amount = amount * 997 / 1000;
        require(amount >= _min, "less than min");
        assert(IERC20(token2).transferFrom(msg.sender, address(this), _amount));
        assert(IERC20(token1).transfer(msg.sender, amount));
        balance1 -= amount;
        balance2 += _amount;
    }


}