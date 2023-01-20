// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
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
/*

实验目的
熟练掌握ERC20标准，熟悉基于xy=k的AMM实现原理，能实现增加/移出流动性，实现多个token的swap     

基础内容
1. 增加/移出流动性 30分   			已完成
2. 交易功能 30分				已完成
3. 实现手续费功能，千分之三手续费 10分		已完成
4. 实现滑点功能 15分				已完成
5. 实现部署脚本 15分				已完成

加分项
1. 实现LPtoken的质押挖矿功能（流动性挖矿），需要自己做市场上产品功能调研然后实现   		尝试完成了


提交方式
在GitHub仓库的自己的分支下提交Pull Request
*/
contract ChangeToken is ERC20{
     using SafeMath for uint256;

    
    address admin;    //部署该合约的地址和手续费收取地址

    address public immutable tokenX;
    address public immutable tokenY;
    // 定义代币x和y的流动池余额
    uint256 public balanceX;
    uint256 public balanceY;
    // 计算k值
    uint256 public constant k ;
  
    constructor(address _tokenX,address _tokenY)ERC20("MYXToken","MYX"){
        tokenX = _tokenX;
        tokenY = _tokenY;
    }
    
    //创建交易池
    function buildPool(uint amountX, uint amountY) public {//初始化交易池的代币数量。
        require(msg.sender == admin, "only admin can use this function"）;
        IERC20(tokenX).transferFrom(msg.sender, address(this), amountX);//从msg.sender（即初始化这个交易池的用户)转移amountX个tokenX到这个交易池的地址。这里使用了IERC20接口来操作tokenA，该接口是用来实现ERC20标准的。
        IERC20(tokenY).transferFrom(msg.sender, address(this), amountY);
        _update();//用于更新交易池的存储量
        uint Liquidity = Math.sqrt(amountX * amountY);//流动性
        _mint(msg.sender, Liquidity);//用于铸造交易池的代币
    }

    //更新交易池中A和B代币的存储量的
     function _update() internal {
        balanceX = IERC20(tokenX).balanceOf(address(this));
        balanceY = IERC20(tokenY).balanceOf(address(this));
    }

    //在交易池中给用户铸造代币
    function _mint(address _to, uint _amount) internal {
        balance[_to] = balance[_to].add(_amount);//首先将_to地址的余额增加_amount，
        emit Transfer(_to, _amount);//然后发出Transfer事件，表示_to地址获得了_amount代币。
    }




    // 增加流动性    
    function addLiquidity(uint256 _amountX, uint256 _amountY) public {//按比例存入
        // 检查用户是否拥有足够的x和y代币
        require(IERC20(_amountX).transferFrom(msg.sender, address(this), _amountX));//如果转移成功，则不执行任何操作；如果转移失败，则抛出错误。
        require(IERC20(_amountY).transferFrom(msg.sender, address(this), _amountY));
        //大于0
        require(_amountX > 0 && _amountY > 0, " can not be 0");

        // 更新流动池余额
        balanceX += _x;
        balanceY += _y;  
        Liquidity = Math.sqrt(amountX * amountY);
        
         uint256 userTotal = _amountX * _amountY;
        userToken[msg.sender] += Math.sqrt(userTotal);

        LPtoken.transfer(msg.sender, Math.sqrt(userTotal));

        // // 计算新的k值
         k = balanceX * balanceY;
        // 铸造新的流动性代币
        _mint(msg.sender,_x * _y); 
    }

    // 移除流动性
    function removeLiquidity(uint256 _x, uint256 _y) public {
        // 检查用户是否拥有足够的流动性
    require(balance[msg.sender] >= _liquidity, "Insufficient liquidity");
        // 计算需要移除的x和y代币数量
        uint256 xToRemove = _x * k / balanceX;
        uint256 yToRemove = _y * k / balanceY;
        // 更新流动池余额
        balanceX -= xToRemove;  
        balanceY -= yToRemove;
        // 计算新的k值
        // k = balanceX * balanceY;
        // 将x和y代币返还给用户
        IERC20(x).transfer(msg.sender, xToRemove);
        IERC20(y).transfer(msg.sender, yToRemove);
    }

    //交易与滑点
    ////X换Y
     function XtoY(uint256 amountIn,uint256 min)public{
        uint256 amountGet = getAmount(amountIn,balanceX,balanceY);
        require(amountGet>=min);

        balanceX += amountIn;
        balanceY -= amountGet;
        require(FT(tokenX).transferFrom(msg.sender,address(this),amountIn));
        require(FT(tokenY).transferFrom(address(this),msg.sender,amountGet));

    }
    //Y换X
    function YtoX(uint256 amountIn,uint256 min)public{
        uint256 amountGet = getAmount(amountIn,balanceY,balanceX);
        require(amountGet>=min);

       balanceY += amountIn;
        balanceX -= amountGet;
        require(FT(tokenY).transferFrom(msg.sender,address(this),amountIn));
        require(FT(tokenX).transferFrom(address(this),msg.sender,amountGet));
    }

     function getAmount(uint256 inputAmount,uint256 inputBalance,uint256 outputBalance) 
    private 
    pure 
    returns (uint256) 
    {
        uint256 fee = inputAmount * 997;//千分之三的手续费
        uint256 numerator = fee * outputBalance;
        uint256 denominator = (inputBalance * 1000) + fee;

        return numerator / denominator;
    }


}