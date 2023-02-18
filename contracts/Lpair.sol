// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./ERC20.sol";
import "./Math.sol";
//2020131141王小萌
error transferFail();
contract Lpair is ERC20{
    uint256  constant MINIMUM_LIQUIDITY =1000;
    address public token01;
    address public token02;
    address public factory;
    uint256 private reserve01;
    uint256 private reserve02;

    event mint(address indexed receipt,uint256 indexed amount01,uint256 indexed amount02);
    event burn(address indexed receipt,uint256 indexed amount01,uint256 indexed amount02);
    event Sync(uint256 reserve01, uint256 reserve02);

    constructor(address _token01,address _token02,address _factory) ERC20("wangUNI","WANG",18){
        token01 = _token01;
        token02 = _token02;
        factory = _factory;
        
    }
    function getReserve()public view returns (uint256 _reserve01,uint256 _reserve02){
        _reserve01 = reserve01;
        _reserve02 = reserve02;
    }
    function _update(uint256 balance01,uint256 balance02)internal {
        reserve01 = balance01;
        reserve02 = balance02;
        emit Sync(reserve01,reserve02);
    }

    function addLiquidity()external returns(uint256 liquidity){
        (uint256 _reserve01,uint256 _reserve02) = getReserve();

        uint256 balance01 = ERC20(token01).balanceOf(address(this));
        uint256 balance02 = ERC20(token02).balanceOf(address(this));

        uint256 amount01 = balance01 - _reserve01;
        uint256 amount02 = balance02 - _reserve02;
        
        if(totalSupply == 0){
            liquidity = Math.sqrt(amount01 * amount02) - MINIMUM_LIQUIDITY;
            _mint(address(0),MINIMUM_LIQUIDITY);
        }else{
        liquidity = Math.min(totalSupply * amount01 /_reserve01,totalSupply * amount02 /_reserve02);
        }
        require(liquidity>=0,"yes");
        _mint(msg.sender,liquidity);

        _update(balance01,balance02);
        emit mint(msg.sender,amount01,amount02);

    }
    

    function Burn(address to,uint256 _amount)public returns(uint256 amount01,uint256 amount02){
        uint256 balance01 = ERC20(token01).balanceOf(address(this));
        uint256 balance02 = ERC20(token02).balanceOf(address(this));

        uint256 liquidity = balanceOf[msg.sender];
        require(_amount<=liquidity,"yes");
        amount01 = _amount * balance01 / totalSupply;
        amount02 = _amount * balance02 / totalSupply;
        require(amount01>0&&amount02>0,"this is must");
        _burn(msg.sender,_amount);

        ERC20(token01).transfer(to,amount01);
        ERC20(token02).transfer(to,amount02);
        balance01 = ERC20(token01).balanceOf(address(this));
        balance02 = ERC20(token02).balanceOf(address(this));

        _update(balance01,balance02);
        emit burn(msg.sender,amount01,amount02);
    }
    function swapToken(address to,uint256 slipPointamount,uint256 amount01,uint256 amount02)external {
        //require(amountmin>0&&amount02>0,"yes");
        require(slipPointamount != 0,"yes");
        (uint256 _reserve01,uint256 _reserve02) = getReserve();
        require(amount01 < _reserve01&& amount02<_reserve02,"yes");
        require(to != token01&& to != token02,"must");
        if(amount01 >0&&amount02==0){
            uint256 amount = getAmountOut(amount02,_reserve02,_reserve01);
            if(slipPointamount>amount){
             revert transferFail();
            }
            ERC20(token02).transfer(to,amount);
            ERC20(token01).transferFrom(msg.sender,address(this),amount01);
        }
        if(amount02 >0&&amount01==0){
            uint256 amount = getAmountOut(amount02,_reserve02,_reserve01);
            if(slipPointamount>amount){
             revert transferFail();
            }
            ERC20(token01).transfer(to,amount);
            ERC20(token02).transferFrom(msg.sender,address(this),amount02);
        }
        uint256 balance01 = ERC20(token01).balanceOf(address(this));
        uint256 balance02 = ERC20(token02).balanceOf(address(this));
        _update(balance01,balance02);
    }

    function getAmountOut(uint256 inputAmount,uint256 inputReserve,uint256 outReserve)internal pure returns(uint256 outAmount){
        require(inputAmount >0&& outReserve > 0,"invalid");
        uint256 fee = inputAmount *997;
        uint256 numerator = fee * outReserve;
        uint256 denominator = (inputReserve  + inputAmount) * 1000;
        outAmount = numerator / denominator;
    }
    function getamount(uint256 inamountA,uint256 inreserveA,uint256 outreserveB)internal pure returns(uint256){
        require(inamountA > 0 && outreserveB >0,"yes");
        return (inamountA * outreserveB) / (inamountA + inreserveA);
    }
    function gettoken01(uint256 amount02)external view returns(uint256){
        require(amount02 > 0,"yes");
        return getamount(amount02,reserve02,reserve01);
    }
    function gettoken02(uint256 amount01)external view returns(uint256){
        require(amount01 > 0,"yes");
        return getamount(amount01,reserve01,reserve02);
    }
    
}