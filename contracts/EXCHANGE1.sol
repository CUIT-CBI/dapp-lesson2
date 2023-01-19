// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {

    address public cryptoDevTokenAAddress;
    address public cryptoDevTokenBAddress;
    

    //交易所继承ERC20，因为我们的交易所将跟踪Crypto Dev LP代币
    constructor(address _CryptoDevtokenA,address _CryptoDevtokenB) ERC20("CryptoDev LP Token", "CDLP") {
        require(_CryptoDevtokenA != address(0), "Token address passed is a null address");
        require(_CryptoDevtokenB != address(0), "Token address passed is a null address");
        cryptoDevTokenAAddress = _CryptoDevtokenA;
        cryptoDevTokenBAddress = _CryptoDevtokenB;

    }

    /** 
    * @dev 返回合约持有的“B令牌”数量
    */
    function getReserve() public view returns (uint) {
        return ERC20(cryptoDevTokenAAddress).balanceOf(address(this));
    }

    /**
    * @dev 为交易所增加流动性.
    */
    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint cryptoDevTokenAReserve = getReserve();
        uint cryptoDevTokenBReserve = getReserve();
        ERC20 cryptoDevTokenA = ERC20(cryptoDevTokenAAddress);
        ERC20 cryptoDevTokenB = ERC20(cryptoDevTokenBAddress);
        /* 
            如果保留为空，则获取用户提供的值`A`和`B`令牌，因为当前没有比率
        */
        if(cryptoDevTokenAReserve == 0) {
            // 将“B”地址从用户帐户转移到合同
            cryptoDevTokenA.transferFrom(msg.sender, address(this), _amount);
            // 获取当前的ABalance，并将“A”数量的LP令牌分配给用户。
            // `“提供的流动性”等于“ABalance”，因为这是第一次使用 
            // 正在合同中添加“A”，因此无论“A”合同是什么，都等于提供的合同
            // 由用户在当前“addLiquidity”调用中调用
            // `需要在“addLiquidity”调用中铸造给用户的流动性“代币”应始终成比例
            // 至用户指定的A
            liquidity = cryptoDevTokenBReserve;
            _mint(msg.sender, liquidity);
        } else {
            /* 
                如果储备不为空，则获取用户提供的值
`A'并根据比率确定有多少“B”代币
需要提供，以防止由于额外的
资产变现能力
            */
           
            uint cryptoDevTokenAAmount = (msg.value * cryptoDevTokenAReserve)/(cryptoDevTokenBReserve);
            
            uint cryptoDevTokenBAmount = (msg.value * cryptoDevTokenBReserve)/(cryptoDevTokenAReserve);
            require(_amount >= cryptoDevTokenBAmount, "Amount of tokens sent is less than the minimum tokens required");
            
            cryptoDevTokenA.transferFrom(msg.sender, address(this), cryptoDevTokenBAmount);
            
            liquidity = (totalSupply() * msg.value)/ cryptoDevTokenAReserve;
            _mint(msg.sender, liquidity);
        }
         return liquidity;
    }

    /** 
    * @dev 返回将返回给用户的A/B代币数量
    *在交换中
    */
    function removeLiquidity(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "_amount should be greater than zero");
        uint cryptoDevTokenAReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        
        uint cryptoDevTokenAAmount = (cryptoDevTokenAReserve * _amount)/ _totalSupply;
       
        uint cryptoDevTokenBAmount = (getReserve() * _amount)/ _totalSupply;
        
        _burn(msg.sender, _amount);
        
        payable(msg.sender).transfer(cryptoDevTokenAAmount);
        
        ERC20(cryptoDevTokenAAddress).transfer(msg.sender, cryptoDevTokenBAmount);
        return (cryptoDevTokenAAmount, cryptoDevTokenBAmount);
    }

    /** 
    * @dev 返回将返回给用户的A/B代币数量
*在交换中
    */
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        
        uint256 inputAmountWithFee = inputAmount * 997;
        
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }

    /** 
    * @dev B代币交换A
    */
    function CryptoDevTokenAToCryptoDevTokenB(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");
        
        ERC20(cryptoDevTokenBAddress).transfer(msg.sender, tokensBought);
    }


    /** 
    * @dev 将B代币交换为A
    */
    function cryptoDevTokenBTocryptoDevTokenA(uint _tokensSold, uint _minA) public {
        uint256 tokenReserve = getReserve();
        
        uint256 ABought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ABought >= _minA, "insufficient output amount");
        
        ERC20(cryptoDevTokenBAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        
        payable(msg.sender).transfer(ABought);
    }
}
