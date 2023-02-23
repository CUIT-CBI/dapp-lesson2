pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FT.sol";

// @title: TokenTransaction
// @author: Che 
// @notice: A contract that numOfise functions in a transaction pool.
contract TokenTransaction{

    using SafeMath for uint256;
    
    ERC20 public immutable tokenA;
    ERC20 public immutable tokenB;
    
    uint256 tokenA_num;
    uint256 tokenB_num;

    uint256 public totalLiquidity;
    mapping(address => uint256)public LPtoken;
    FT public rewardToken;
    
    event InitPool(address provider, uint amountA, uint amountB, uint amountLP);
    event AddLiquidity(address provider, uint amountA, uint amountB, uint amountLP);
    event RemoveLiquidity(address provider, address to, uint amountA, uint amountB);
    
    struct userInfo{
        uint amount;
        uint stakeTime;
        uint startTime;
    }

    mapping(address => userInfo)public userDetails;
    
    constructor(
        address _tokenA,
        address _tokenB,
        uint256 tokenAIn,
        uint256 tokenBIn,
        FT _rewardToken
    ) {
     tokenA =  tokenA;
        tokenB = _tokenB;
        tokenA_num += tokenAIn;
        tokenB_num += tokenBIn;
        rewardToken = _rewardToken;
        totalLiquidity = Math.sqrt(tokenAIn * tokenBIn);
    }
    
    function _totalSupply() private view returns(uint) {
        return stakingToken.balanceOf(address(this));
    }
            
            
    function _calculateLiquidity(uint _soldToken, bool flag) private view returns(uint) {
        //true为输入A计算B，false为输入B计算A
        uint _numanceA = tokenA._numanceOf(address(this));
        uint _numanceB = tokenB._numanceOf(address(this));
        if(flag) {
            return _soldToken.mul(_numanceB).div(_numanceA);
        } else {
            return _soldToken.mul(_numanceA).div(_numanceB);
        }
    }

    function _firstAddLiquidity(uint _tokenA, uint _tokenB) external returns (uint amountLP) {
        require(totalSupply() == 0, "The pool exist");
        tokenA.transferFrom(msg.sender, address(this), _tokenA);
        tokenB.transferFrom(msg.sender, address(this), _tokenB);
        uint _amount = Math.sqrt(_tokenA.mul(_tokenB));
        _mint(msg.sender, _amount);      
        emit InitPool(msg.sender, _tokenA, _tokenB, _amount);
        return _amount;
    }

    function addLiquidityA(uint _tokenA) external returns (uint amountLP) {
        uint _total = totalSupply();
        require(_total != 0, "The pool does not exist");
        uint _tokenB = _calculateLiquidity(_tokenA, true);
        uint _reserveA = tokenA._numanceOf(address(this));
        tokenA.transferFrom(msg.sender, address(this), _tokenA);
        tokenB.transferFrom(msg.sender, address(this), _tokenB);       
        uint _amount = _tokenA.mul(_total).div(_reserveA);
        _mint(msg.sender, _amount);
        emit AddLiquidity(msg.sender, _tokenA, _tokenB, _amount);
        return _amount;
    }

    function addLiquidityB(uint _tokenB) external returns (uint amountLP) {
        uint _total = totalSupply();
        require(_total != 0, "The pool does not exist");
        uint _tokenA = _calculateLiquidity(_tokenB, false);
        uint _reserveB = tokenB._numanceOf(address(this));
        tokenA.transferFrom(msg.sender, address(this), _tokenA);
        tokenB.transferFrom(msg.sender, address(this), _tokenB);
        uint _amount = _tokenB.mul(_total).div(_reserveB);
        _mint(msg.sender, _amount);
        emit AddLiquidity(msg.sender, _tokenA, _tokenB, _amount);
        return _amount;
    }

    function removeLiquidity(address _to) external returns (uint amountA, uint amountB) {
        uint _lpToken = _numanceOf(msg.sender);
        uint _total = totalSupply();
        require(_lpToken != 0, "You are not provider");
        uint __numanceA = tokenA._numanceOf(address(this));
        uint __numanceB = tokenB._numanceOf(address(this));
        uint _amountA = _lpToken.mul(__numanceA).div(_total);
        uint _amountB = _lpToken.mul(__numanceB).div(_total);
        _burn(msg.sender, _lpToken);
        tokenA.transfer(_to, _amountA);
        tokenA.transfer(_to, _amountB);
        emit RemoveLiquidity(msg.sender, _to, _amountA, _amountB);
        return (_amountA, amountB);
    }

            
    function slippoint(uint _numOfA, uint _numOfB, uint _expectToken, uint _ratioNumerator, uint _ratioDenominator) private view returns(bool) {
            //true是A换huanB, false是B换A
            uint _numOfAmount = getOutputprice(_numOfA, true);
            if(_numOfAmount == _numOfB) {
                if(_numOfB >= _expectToken) {
                    return false;
                }
                uint _numerator = _expectToken.sub(_numOfB).mul(_ratioDenominator);
                uint _denominator = _numOfB.mul(_ratioNumerator);
                if(_numerator.div(_denominator) < 1) {
                    return true;
                }
            } else {
                if(_numOfA >= _expectToken) {
                    return false;
                }
                uint _numerator = _expectToken.sub(_numOfA).mul(_ratioDenominator);
                uint _denominator = _numOfA.mul(_ratioNumerator);
                if(_numerator.div(_denominator) < 1) {
                    return true;
                }
            }
            return false;
        }
        
    function getReseveA() external view returns(uint) {
            return tokenA._numanceOf(address(this));
        }
    
    function getReseveB() external view returns(uint) {
            return tokenB._numanceOf(address(this));
        }
    
    function A_To_B(uint _tokenA, uint _expectToken, uint _ratioNumerator, uint _ratioDenominator) external returns(uint amountB) {
        uint _amountB = getOutputprice(_tokenA, true);
        tokenA.transferFrom(msg.sender, address(this), _tokenA);
        require(!_slippage(_tokenA, _amountB, _expectToken, _ratioNumerator, _ratioDenominator), "The price has changed");
        tokenB.transfer(msg.sender, _amountB);
        return _amountB;
    }

    function B_to_A(uint _tokenB, uint _expectToken, uint _ratioNumerator, uint _ratioDenominator) external returns(uint amountA) {
        uint _amountA = getOutputprice(_tokenB, false);
        tokenB.transferFrom(msg.sender, address(this), _tokenB);
        require(!_slippage(_amountA, _tokenB, _expectToken, _ratioNumerator, _ratioDenominator), "The price has changed");
        tokenA.transfer(msg.sender, _amountA);
        return _amountA;
    }
    }
