// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract YHswapERC20 {

string  public constant name ="YHLP";
string  public constant symbol="YH";
uint256 public constant decimals=18;
mapping(address =>uint256) public balances;
mapping(address =>mapping(address=>uint256)) public allowances;
uint256 public totalLiquidity;

   
    function _approve(address owner, address spender, uint value) private  {
        allowances[owner][spender] = value;
        
    }

    function _transfer(address from, address to, uint value) private {
        balances[from] = balances[from]-value;
        balances[to] = balances[to]+value;
     
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }


    function transferFrom(address from, address to, uint value) external returns (bool) {
         require(allowances[from][msg.sender]>=value);
         allowances[from][msg.sender] = allowances[from][msg.sender]-value;
         _transfer(from, to, value);
        return true;
    }

}
