// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/*
1. 增加/移出流动性 
2. 交易功能     k值 = (池内A + 存入A)*(池内B - 取出B )==》用a换取b
3. 实现手续费功能，千分之三手续费    (手续费从将要兑换的币中扣除，留在池内)==》可以不判断b取出之后是否足够
4. 实现滑点功能   滑点 = （理想取出-实际取出）*100/理想取出
5. 实现部署脚本    ==》ts 有点难
*/

contract FTSwap {
    address public tokenA;
    address public tokenB;

    // 池中token数量
    uint256 public reserveA; 
    uint256 public reserveB;

    // 交易池的地址
    address public factory;
    
    // 池中token数量乘积
    uint256 public k;

    //当前兑换率(计算时乘以1000减少误差) ==》 1/2*1000=500
    uint256 rate;

    mapping(address => uint256) public providerA;
    mapping(address => uint256) public providerB;

        // 初始化代币地址
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        // 工厂就为部署者地址
        factory = msg.sender;
    }
        //更新兑换率
    function update() private{
        
        if(reserveA > reserveB){
            rate = (reserveA * 1000) / reserveB;
        }else{
            rate = (reserveB * 1000) / reserveA;
        }
    }

    // 初始化交易池地址
    function initialPool(uint256 countA, uint256 countB) public{
        require(msg.sender == factory,"No permission initialization");
        reserveA = countA;
        reserveB = countB;
        //更新k值
        k = reserveA * reserveB;
        //更新兑换率
        update();
        ERC20(tokenA).transferFrom(msg.sender, address(this), countA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), countB);
    }

    //增加流动性 ==> 默认a和b比例应该一样
    function addLiquidity(uint256 countA) public returns(uint256){
        require(countA > 0,"The value stored is invalid");
        //计算应存入的B数量（想要满足池中A与B比例）
        uint256 countB;
        if(reserveA > reserveB){
            countB = (countA * 1000) / rate;
        }else{
            countB = (countA * rate) / 1000;
        }
        
        //检查流动性提供者的余额是否充足
        require(ERC20(tokenA).balanceOf(msg.sender) >= countA && ERC20(tokenB).balanceOf(msg.sender) >= countB,
        "Insufficient balance");

        //更新池中数量以及K值
        reserveA += countA;
        reserveB += countB;
        k = reserveA * reserveB;

        ERC20(tokenA).transferFrom(msg.sender, address(this), countA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), countB);
        
        //更新流动性提供者在池中的资产余额
        providerA[msg.sender] += countA;
        providerB[msg.sender] += countB;

        //返回存入B的数量
        return countB;
    }

    //移出流动性,只能按比例移出
    function removeLiquidity(uint256 countA) public returns(uint256){
        require(countA > 0,"The value stored is invalid");
        uint256 countB;
        if(reserveA > reserveB){
            countB = (countA * 1000) / rate;
        }else{
            countB = (countA * rate) / 1000;
        }

        //判断流动性提供者在池中的余额是否充足
        require(providerA[msg.sender] >= countA && providerB[msg.sender] >= countB,
        "you don not enough balance in pool");
        //判断池中储备量是否充足
        require(reserveA >= countA && reserveB >= countB,"pool balance is not enough");

        //更新池中数量以及K值
        reserveA -= countA;
        reserveB -= countB;
        k = reserveA * reserveB;

        ERC20(tokenA).transfer(msg.sender, countA);
        ERC20(tokenB).transfer(msg.sender, countB);

        providerA[msg.sender] -= countA;
        providerB[msg.sender] -= countB;

        //返回移出B的数量
        return countB;
    }

    //交易功能,滑点，手续费（tokenA换tokenB），设置的滑点为 差值率*100  
    function swapAtoB(uint256 countA, uint256 point) public returns(uint256){
        require(countA > 0,"The value stored is invalid");
        //通过换取率计算用户期望
        uint256 hopeB;
        if(reserveA > reserveB){
            hopeB = (countA * 1000) / rate;
        }else{
            hopeB = (countA * rate) / 1000;
        }

        //通过k值计算，用户实际能换取的数量
        uint256 countB = reserveB - k / (reserveA + countA);
        
        //计算期望值与实际值的差值占期望值的百分比乘以100
        uint256 split = (hopeB - countB) * 100 / hopeB;  

        //检查用户余额中tokenA是否充足
        require(ERC20(tokenA).balanceOf(msg.sender) >= countA,"Insufficient balance");
        //检查池中tokenB是否充足
        require(reserveB >= countB,"pool have not enough tokenB");
        //检查是否满足设置的滑点
        require(split <= point,"Excessive slip point");

        //手续费(千分之三),手续费从将要转出的币中扣除，留在池内
        uint256 commission = countB * 3 / 1000;
        
        //更新池中数量以及K值
        reserveA += countA;
        reserveB -= (countB - commission);
        k = reserveA * reserveB;

        ERC20(tokenA).transferFrom(msg.sender, address(this), countA);
        ERC20(tokenB).transfer(msg.sender, countB - commission);

        //更新兑换率
        update();
        //返回最后换取的数量
        return (countB - commission);
    }

    //交易功能,滑点，手续费（tokenB换tokenA），设置的滑点为 差值率*100  
    function swapBtoA(uint256 countB, uint256 point) public returns(uint256){
        require(countB > 0,"The value stored is invalid");
        //通过换取率计算用户期望
        uint256 hopeA;
        if(reserveA > reserveB){
            hopeA = (countB * rate) / 1000;
        }else{
            hopeA = (countB * 1000) / rate;
        }

        //通过k值计算，用户实际能换取的数量
        uint256 countA = reserveA - k / (reserveB + countB);
        
        //计算期望值与实际值的差值占期望值的百分比乘以100
        uint256 split = (hopeA - countA) * 100 / hopeA;  

        //检查用户余额中tokenA是否充足
        require(ERC20(tokenB).balanceOf(msg.sender) >= countB,"Insufficient balance");
        //检查池中tokenB是否充足
        require(reserveA >= countA,"pool have not enough tokenB");
        //检查是否满足设置的滑点
        require(split <= point,"Excessive slip point");

        //手续费(千分之三),手续费从将要转出的币中扣除，留在池内
        uint256 commission = countA * 3 / 1000;
        
        //更新池中数量以及K值
        reserveA -= (countA - commission);
        reserveB += countB;
        k = reserveA * reserveB;

        ERC20(tokenA).transferFrom(msg.sender, address(this), countB);
        ERC20(tokenB).transfer(msg.sender, countA - commission);

        //更新兑换率
        update();

        //返回最后换取的数量
        return countA - commission;
    }
}