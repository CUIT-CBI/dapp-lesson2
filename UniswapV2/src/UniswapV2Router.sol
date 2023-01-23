// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./libraries/FT.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract UniswapV2Router{

    //管理员地址
    address admin;

    FT public tokenA;
    FT public tokenB;
    FT public LPtoken;

    uint256 amountA;
    uint256 amountB;
    uint256 public liquidity;
    uint256 rate;

    //记录变量大小，协助比例计算
    bool private Big_left;

    mapping(address => uint256) public userToken;

    constructor(FT _LPtoken, FT _tokenA, FT _tokenB) {
        admin = msg.sender;
        tokenA = _tokenA;
        tokenB = _tokenB;
        LPtoken = _LPtoken;
    }

    //初始化交易池，注入流动性
    function initialize(uint256 _amountA, uint256 _amountB) public payable {
        require(msg.sender == admin);
        amountA = _amountA;
        amountB = _amountB;
        liquidity = amountA * amountB;
        if(_amountA > _amountB){
            rate = _amountA / amountB;
            Big_left
     = true;
        }else{
            rate = _amountB / amountA;
            Big_left
     = false;
        }
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);
    }

    //增加流动性(按比例存入)
    function addLiquidity(uint256 _amountA, uint256 _amountB) public payable returns(uint256){
        require(_amountA > 0 && _amountB > 0);

        amountA += _amountA;
        amountB += _amountB;
        liquidity = amountA * amountB;

        uint256 totalAmount = _amountA * _amountB;
        userToken[msg.sender] += Math.sqrt(totalAmount);

        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        LPtoken.transfer(msg.sender, Math.sqrt(totalAmount));
        return Math.sqrt(totalAmount);
    }

    //移出流动性
    function removalLiquidity(uint256 _LPtoken) public payable{
        require(_LPtoken > 0);
        require(userToken[msg.sender] > 0);

        uint256 _amountA;
        uint256 _amountB;
        if(Big_left
 == true){
            _amountB = _LPtoken / (Math.sqrt(rate));
            _amountA = _amountB * rate; 
        }else{
            _amountA = _LPtoken / (Math.sqrt(rate));
            _amountB = _amountA * rate; 
        }

        amountA -= _amountA;
        amountB -= _amountB;
        liquidity = amountA * amountB;

        userToken[msg.sender] -= _LPtoken;

        LPtoken.transferFrom(msg.sender, address(this), _LPtoken);

        tokenA.transfer(msg.sender, _amountA);
        tokenB.transfer(msg.sender, _amountB);
    }

    //交易&滑点功能实现
    function transfor_to_tokenB(uint256 _amountA) public payable returns(uint256){
        uint256 _amountB;
        if(Big_left
 == true){
            _amountB = _amountA / rate;
        }else{
            _amountB = _amountA * rate;
        }

        require(_amountB < tokenB.balanceOf(address(this)));
        //手续费
        uint256 Service_Charge = _amountB * 3 / 1000;

        amountA += _amountA;
        amountB -= _amountB;

        liquidity = amountA * amountB;

        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transfer(msg.sender, _amountB - Service_Charge);
        tokenB.transfer(admin, Service_Charge);
        return _amountB - Service_Charge;
    }

    function transfor_to_TokenA(uint256 _amountB) public payable returns(uint256){
        uint256 _amountA;
        if(Big_left
 == true){
            _amountA = _amountB * rate;
        }else{
            _amountA = _amountB / rate;
        }

        require(_amountA < tokenA.balanceOf(address(this)));
        //手续费
        uint256 Service_Charge = _amountA * 3 / 1000;

        amountA -= _amountA;
        amountB += _amountB;

        liquidity = amountA * amountB;

        tokenB.transferFrom(msg.sender, address(this), _amountB);
        tokenA.transfer(msg.sender, _amountA - Service_Charge);
        tokenA.transfer(admin, Service_Charge);
        return _amountA - Service_Charge;
    }
}