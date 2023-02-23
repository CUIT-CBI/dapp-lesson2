// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FT.sol";
import "./Math.sol";
contract pair is FT{

    address public token1;
    address public token2;

    uint256 private reserve1;           
    uint256 private reserve2;    

    //Create pool
        constructor(address _token1, address _token2) FT ("LPtoken","LP") {
        token1 = _token1;
        token2 = _token2;
    }

    //get capital reserves
    function getReserves() public view returns (uint256 _reserve1, uint256 _reserve2) {
        _reserve1 = reserve1;
        _reserve2 = reserve2;
    }

    // update capital reserves
    function _update() private {
        reserve1 = ERC20(token1).balanceOf(address(this));
        reserve2 = ERC20(token2).balanceOf(address(this));
    }

    // First add liquidity
    function firstAdd(uint256 amount1,uint256 amount2) external returns(uint256 LP){
        ERC20(token1).transferFrom(msg.sender, address(this), amount1);
        ERC20(token2).transferFrom(msg.sender, address(this), amount2);
        LP = Math.sqrt(amount1*amount2);
        _mint(msg.sender,LP);
        _update();
    }

    //add liquidity
    function addLP(address token,uint256 amount) external returns (uint256 LP) {
         (uint256 _reserve1, uint256 _reserve2) = getReserves();
         uint currentTotalLP = ERC20.totalSupply();
         require(token == token1 || token == token2,"Invalid address");
         uint amount1;
         uint amount2;
        if(token == token1){
             amount1 = amount;
             amount2 = amount1/(_reserve1/_reserve2);
        }else if(token == token2){
             amount2 = amount;
             amount1 = amount2*(_reserve1/_reserve2);
        }
       ERC20(token1).transferFrom(msg.sender, address(this), amount1);
       ERC20(token2).transferFrom(msg.sender, address(this), amount2);
       LP = Math.min(amount1/ _reserve1*currentTotalLP, amount2/ _reserve2*currentTotalLP);//按比例分配，一般是一样的
      _mint(msg.sender,LP);
      _update();
    }

    //remove liquidity
        function removeLP(uint LP)external returns(uint256 amount1,uint256 amount2){
            (uint256 _reserve1, uint256 _reserve2) = getReserves();
            uint256 currentTotalLP = ERC20.totalSupply();
            require(_totalSupply > LP,"not enough");
            amount1 = _reserve1*LP/currentTotalLP;
            amount2 = _reserve2*LP/currentTotalLP;
            ERC20(token1).transfer(msg.sender,amount1);
            ERC20(token2).transfer(msg.sender,amount2);
            _burn(msg.sender,LP);
            _update();
        }

    //swapfee slipgage
        function swap(uint256 amountIn,address token,uint slipgageLimit)external returns(uint256 amountOut,address tokenN){
            require(token == token1 || token == token2,"Invalid address");
            (uint256 _reserve1, uint256 _reserve2) = getReserves();
            uint slipgage;
            if(token==token1){
                amountOut == _reserve2-(_reserve1*_reserve2)/(_reserve1+amountIn)*997/1000;
                //减少百分之三
                slipgage = amountIn/_reserve2;
                //token2单价滑点：token1/token2
                tokenN = token1;
            }else{
                amountOut == _reserve1-(_reserve1*_reserve2)/(_reserve2+amountIn)*997/1000;
                slipgage = amountIn/_reserve1;
                tokenN = token2;
            }
            require(slipgage<=slipgageLimit,"out of slipgageLimit");
            ERC20(token).transferFrom(msg.sender,address(this),amountIn);
            ERC20(tokenN).transfer(msg.sender,amountOut);
            _update();

        }
        }
