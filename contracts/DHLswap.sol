// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

//简化一手为tokenA,tokenB的专属流动池，省去pair合约,集成factory合约
contract DHLswap is ERC20 {
    using SafeMath for uint256;
    uint minLiquidity;
    address public immutable tokenA;//tokenA合约地址
    address public immutable tokenB;//tokenB合约地址

    event Init(address provider, uint tokenAamount, uint tokenBamount, uint LPamount);
    event AddLiquidity(address provider, uint tokenAamount, uint tokenBamount, uint LPamount);
    event RemoveLiquidity(address provider, address to, uint tokenAamount, uint tokenBamount);
    event SwapAtoB(address trader, uint soldToken, uint buyToken);
    event SwapBtoA(address trader, uint soldToken, uint buyToken);


    constructor(address _tokenA, address _tokenB) ERC20("UNI", "DHLLP") {
        require(_tokenA != address(0) && _tokenB != address(0), "Address equals zero");
        require(_tokenA != _tokenB, "tokenA equals tokenB");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

 
    //增加流动性
    function addLiquidity(uint tokenAamount, uint tokenBamount ) external returns (uint LPtoken) {
        require(tokenAamount>0 && tokenBamount > 0,"amount below zero");
        uint _total = totalSupply();
        //如果_total为0，则是首次增加流动性
        if(_total == 0){
        ERC20(tokenA).transferFrom(msg.sender, address(this), tokenAamount);
        ERC20(tokenB).transferFrom(msg.sender, address(this), tokenBamount);
        uint _amount = Math.sqrt(tokenAamount.mul(tokenBamount));
        //赋值最小流动性
        minLiquidity=_amount;
        _mint(msg.sender, _amount);      
        emit Init(msg.sender, tokenAamount, tokenBamount, _amount);
        return _amount;
        }

        else{
        //计算实际增加流动性投入的tokenA和tokenB
        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));
        uint tokenAmin = tokenBamount.mul(balanceA).div(balanceB);
        uint tokenBmin = tokenAamount.mul(balanceB).div(balanceA);
        if(tokenAamount<tokenAmin){tokenBamount=tokenBmin;}
        else {tokenAamount=tokenAmin;}//计算完成
        ERC20(tokenA).transferFrom(msg.sender, address(this), tokenAamount);
        ERC20(tokenB).transferFrom(msg.sender, address(this), tokenBamount);       
        uint _amount = tokenAamount.mul(_total).div(balanceA);
        _mint(msg.sender, _amount);
        emit AddLiquidity(msg.sender, tokenAamount, tokenBamount, _amount);
        return _amount;
        }
    }

    //移出流动性
    function removeLiquidity(address _to,uint liquidityOut) external returns (uint amountA, uint amountB) {
        uint balanceLP = balanceOf(msg.sender);
        require(balanceLP >= 0, " not liquidity provider"); 
        require(balanceLP - liquidityOut >= 0,"balanceLP is not enough");
        uint _total = totalSupply();
        //判断移出后流动性是否大于最小流动性
        require(_total - liquidityOut >= minLiquidity,"Liquidity is too low");
        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));
        uint _amountA = liquidityOut.mul(_balanceA).div(_total);
        uint _amountB = liquidityOut.mul(_balanceB).div(_total);
        _burn(msg.sender, liquidityOu);
        ERC20(tokenA).transfer(_to, _amountA);
        ERC20(tokenB).transfer(_to, _amountB);
        emit RemoveLiquidity(msg.sender, _to, _amountA, _amountB);
        return (_amountA, amountB);
    }
    //交易
    function SwapAtoB(uint tokenAamount, uint expectedTokenBPerTokenA) external returns(uint amountB) {
        require(tokenAamount>0 &&  expectedTokenBPerTokenA>0 , "fuck off");
        uint priceB,uint amountB = getPriceAndAmount(tokenAamount, true);//计算实际换得数与单价
        require( ! slippage(expectedTokenBPerTokenA, priceB), "The price is not expected");//滑点判断
        ERC20(tokenA).transferFrom(msg.sender, address(this), tokenAamount);
        ERC20(tokenB).transfer(msg.sender, amountB);
        emit SwapAtoB(msg.sender, tokenAamount, amountB);
        return amountB;
    }

    function SwapBtoA(uint tokenBamount, uint expectedTokenAPerTokenB) external returns(uint amountA) {
        require(tokenBamount>0 &&  expectedTokenAPerTokenB>0 , "fuck off");
        uint priceA,uint amountA = getPriceAndAmount(tokenBamount, false);
        require( ! slippage(expectedTokenAPerTokenB, priceA), "The price is not expected");
        ERC20(tokenB).transferFrom(msg.sender, address(this), tokenBamount);
        ERC20(tokenA).transfer(msg.sender, amountA);
        emit SwapBtoA(msg.sender, tokenBamount, amountA);
        return amountA;
    }
    //手续费 千分之三, 选择从换来的币种中扣除
    function getPriceAndAmount(uint tokenAmount, bool flag) public view returns(uint Price,uint Amount) {//计算实际换得的币数和币单价        
        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));
        uint k = balanceA.mul(balanceB);
        //true为SwapAtoB，false为SwapBtoA
        if(flag == true) {
             uint leftB = k.div(balanceA.add(tokenAmount));
             Amount = (balanceB.sub(leftB)).mul(997).div(1000);
             //计算的price为滑点计算参数
             Price = Amount.div(tokenAmount);
        } else {
             uint leftA = k.div(balanceB.add(tokenAmount));
             Amount = (balanceA.sub(leftA)).mul(997).div(1000);
              Price = Amount.div(tokenAmount);
        }
    } 

    //滑点 设置为百分之一
    function slippage(uint expected, uint real) private view returns(bool) {
        if(expected>real){
            uint diff = expected - real;//期望单币换取数-实际单币换取数
            if(diff.div(expected) > 1.div(100)){return false;}
            else {return true;}
        }
        else {return true;}
    }

