// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FT.sol";
import "./Math.sol";
contract pair is FT{

    // uint public constant MINIMUM_LIQUIDITY = 10**3;
    address public token0;
    address public token1;

    uint256 private reserve0;           
    uint256 private reserve1;           
    

//获取资金储备数
    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }


        constructor(address _token0, address _token1) FT("LPtoken","LP") {
        token0 = _token0;
        token1 = _token1;
    }//创建资金池

    // 更新资金储备数
    function _update() private {
        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));
    }

    // 第一次添加流动性
    function firstAdd(uint256 amount0,uint256 amount1) external returns(uint256 LP){
        FT(token0).transferFrom(msg.sender, address(this), amount0);
        FT(token1).transferFrom(msg.sender, address(this), amount1);
        LP = Math.sqrt(amount0*amount1);//LP凭证
        _mint(msg.sender,LP);
         _update();
    }
    function addLP(address token,uint256 amount) external returns (uint256 LP) {
         (uint256 _reserve0, uint256 _reserve1) = getReserves();
         uint _totalSupply = ERC20.totalSupply();
         require(token == token0 || token == token1,"Invalid address");
         uint amount0;
         uint amount1;
        if(token == token0){
             amount0 = amount;
             amount1 = amount0/(_reserve0/_reserve1);
        }else if(token == token1){
             amount1 = amount;
             amount0 = amount1*(_reserve0/_reserve1);
        }
       ERC20(token0).transferFrom(msg.sender, address(this), amount0);
       ERC20(token1).transferFrom(msg.sender, address(this), amount1);
       //试时分别计算一下
       LP = Math.min(amount0/ _reserve0*_totalSupply, amount1/ _reserve1*_totalSupply);
      _mint(msg.sender,LP);
        _update();
    }
    //移除流动性
        function removeLP(uint LP)external returns(uint256 amount0,uint256 amount1){
            (uint256 _reserve0, uint256 _reserve1) = getReserves();
            uint256 _totalSupply = ERC20.totalSupply();
            require(_totalSupply > LP,"not enough");
            amount0 = _reserve0*LP/_totalSupply;
            amount1 = _reserve1*LP/_totalSupply;
            ERC20(token0).transfer(msg.sender,amount0);
            ERC20(token1).transfer(msg.sender,amount1);
            _burn(msg.sender,LP);
            _update();
        }
        //交易时手续费和滑点实现
        function swap(uint256 amountIn,address token,uint slipgageLimit)external returns(uint256 amountOut,address tokenN){
            require(token == token0 || token == token1,"Invalid address");
            (uint256 _reserve0, uint256 _reserve1) = getReserves();
            uint slipgage;
            if(token==token0){
                amountOut == _reserve1-(_reserve0*_reserve1)/(_reserve0+amountIn)*997/1000;
                slipgage = amountIn/_reserve1;
                tokenN = token0;
            }else{
                amountOut == _reserve0-(_reserve0*_reserve1)/(_reserve1+amountIn)*997/1000;
                slipgage = amountIn/_reserve0;
                tokenN = token1;
            }
            require(slipgage<=slipgageLimit,"out of slipgageLimit");
            ERC20(token).transferFrom(msg.sender,address(this),amountIn);
            ERC20(tokenN).transfer(msg.sender,amountOut);
            _update();

        }
}

