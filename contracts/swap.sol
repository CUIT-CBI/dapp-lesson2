// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

import "./FT.sol";

contract uniswap {

    address private tokenA;
    address private tokenB;

    //流动性总量 k
    uint totalLiquidity = 0;

    //总手续费
    uint totalfee = 0;

    constructor (address _tokenA,address _tokenB) {
        require(_tokenA != address(0) && _tokenB != address(0) );
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    //流动性注入者的流动性
    mapping (address => uint) userLiquidity;
    //不同代币的含量
    mapping (address => uint) tokenContent;

    //增加流动性
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require (amountA != 0 && amountB != 0);

        //若是首次注入则不需考虑按比例注入 后续注入则均需考虑
        if(totalLiquidity != 0){
            require(amountA / amountB == tokenContent[tokenA] / tokenContent[tokenB],"The request does not meet the requirements");
        }

        _addLiquidity(msg.sender,amountA,amountB);
    }

    function _addLiquidity(address _user,uint256 amountA,uint256 amountB) internal {

        totalLiquidity += amountA * amountB;
        userLiquidity[_user] += amountA * amountB;
        tokenContent[tokenA] += amountA;
        tokenContent[tokenB] += amountB;

        FT tfA = FT(tokenA);
        tfA.transferFrom(_user,address(this),amountA);

        FT tfB = FT(tokenB);
        tfB.transferFrom(_user,address(this),amountB);
    }

    //移出流动性
    function removeLiquidity(uint256 amountA,uint256 amountB) external {
        require(amountA / amountB == tokenContent[tokenA] / tokenContent[tokenB],"The request does not meet the requirements");
        require(userLiquidity[msg.sender] >= amountA * amountB,"Insufficient balance");
        _removeLiquidity(msg.sender,amountA,amountB);
    }

    function _removeLiquidity(address _user,uint256 amountA,uint256 amountB) internal {
        uint getfee = totalfee * (userLiquidity[_user] / totalLiquidity);

        totalLiquidity -= amountA * amountB;
        userLiquidity[_user] -= amountA * amountB;
        tokenContent[tokenA] -= amountA;
        tokenContent[tokenB] -= amountB;

        FT tfA = FT(tokenA);
        tfA.transfer(_user,amountA);

        FT tfB = FT(tokenB);
        tfB.transfer(_user,amountB);

        if(tokenContent[tokenA] > tokenContent[tokenB]){
            tfB.transfer(_user,getfee);
        }else{
            tfA.transfer(_user,getfee);
        }

        totalfee -= getfee;

    }

    //用A交易B
    function AtoB_token(uint256 inAmountA) external {
        _AtoB_token(msg.sender,inAmountA);
    }

    function _AtoB_token(address _user,uint256 inAmountA) internal {
        uint256 newAmountA = tokenContent[tokenA] + inAmountA;
        uint256 newAmountB = totalLiquidity / newAmountA;
        uint256 outAmountB = tokenContent[tokenB] - newAmountB;

        uint256 tempfee = (outAmountB * 3) / 1000;

        totalfee += tempfee;

        require(tokenContent[tokenB] >= outAmountB,"The target token balance is insufficient");

        tokenContent[tokenA] += inAmountA;
        tokenContent[tokenB] -= outAmountB;

        FT tfA = FT(tokenA);
        tfA.transferFrom(_user,address(this),inAmountA);        

        FT tfB = FT(tokenB);
        tfB.transfer(_user,outAmountB - tempfee);
    }

    //用B交易A
    function BtoA_token(uint256 inAmountB) external { 
        _BtoA_token(msg.sender, inAmountB);
    }

    function _BtoA_token(address _user,uint256 inAmountB) internal {
        uint256 newAmountB = tokenContent[tokenB] + inAmountB;
        uint256 newAmountA = totalLiquidity / newAmountB;
        uint256 outAmountA = tokenContent[tokenA] - newAmountA;

        uint256 tempfee = (outAmountA * 3) / 1000;

        totalfee += tempfee;

        require(tokenContent[tokenA] >= outAmountA,"The target token balance is insufficient");

        tokenContent[tokenB] += inAmountB;
        tokenContent[tokenA] -= outAmountA;

        FT tfB = FT(tokenB);
        tfB.transferFrom(_user,address(this),inAmountB);        

        FT tfA = FT(tokenA);
        tfA.transfer(_user,outAmountA - tempfee);
    }


    // //获得aTob汇率
    // function getAtoBExchangeRate() view external returns (uint256) {
    //     return tokenContent[tokenA] / tokenContent[tokenB];
    // }

    // //获得bToa汇率
    // function getBtoAExchangeRate() view external returns (uint256) {
    //     return tokenContent[tokenB] / tokenContent[tokenA];
    // }

    // //获得注入流动性时的比例
    // function getLiquidityRatio() view external returns (uint256) {
    //     return tokenContent[tokenA] / tokenContent[tokenB];
    // }

}
