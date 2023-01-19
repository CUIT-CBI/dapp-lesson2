pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LooneySwapPool is ERC20 {
    address public token0 = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address public token1 = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // Reserve of token 0
    uint public reserve0;

    // Reserve of token 1
    uint public reserve1;

    uint public constant INITIAL_SUPPLY = 1000;
    using SafeMath  for uint;
    constructor() ERC20("PRL", "PRL") {
    }
        //增加pool的流动性
    function add(uint amount0, uint amount1) public {
        assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));            //转入token
        assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));

        uint reserve0After = reserve0 + amount0;
        uint reserve1After = reserve1 + amount1;

        if (reserve0 == 0 && reserve1 == 0) {                                           //首次向pool加入token
            _mint(msg.sender, INITIAL_SUPPLY);
        } else {
            uint currentSupply = totalSupply();                                         //计算比例,发行LP
            uint newSupplyGivenReserve0Ratio = reserve0After * currentSupply / reserve0;
            uint newSupplyGivenReserve1Ratio = reserve1After * currentSupply / reserve1;
            uint newSupply = Math.min(newSupplyGivenReserve0Ratio, newSupplyGivenReserve1Ratio);
            _mint(msg.sender, newSupply - currentSupply);
        }

        reserve0 = reserve0After;
        reserve1 = reserve1After;
    }

//移除流动性
    function remove(uint amount) public {
        assert(transfer(address(this), amount));

        uint currentSupply = totalSupply();
        uint amount0 = amount * reserve0 / currentSupply;
        uint amount1 = amount * reserve1 / currentSupply;

        _burn(address(this), amount);

        assert(IERC20(token0).transfer(msg.sender, amount0));
        assert(IERC20(token1).transfer(msg.sender, amount1));
        reserve0 = reserve0 - amount0;
        reserve1 = reserve1 - amount1;
    }

    //获取价格
    function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint _reserve0, uint _reserve1) {
        uint newReserve0;
        uint newReserve1;
        uint k = reserve0 * reserve1;

        if (fromToken == token0) {
            newReserve0 = amountIn + reserve0;
            newReserve1 = k / newReserve0;
            amountOut = reserve1 - newReserve1;
        } else {
            newReserve1 = amountIn + reserve1;
            newReserve0 = k / newReserve1;
            amountOut = reserve0 - newReserve0;
        }

        _reserve0 = newReserve0;
        _reserve1 = newReserve1;
    }
// minAmountOut即为设置的滑点值,通过getAmountOut计算出价格,限制价格大于设置的滑点值
    function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to) public {
        require(amountIn > 0 && minAmountOut > 0, 'Amount invalid');
        require(fromToken == token0 || fromToken == token1, 'From token invalid');
        require(toToken == token0 || toToken == token1, 'To token invalid');
        require(fromToken != toToken, 'From and to tokens should not match');

        (uint amountOut, uint newReserve0, uint newReserve1) = getAmountOut(amountIn, fromToken);

        require(amountOut >= minAmountOut, 'Slipped... on a banana');                                   //滑点
        uint amountOutAdjust  = amountOut.mul(997).div(1000);                                           //少给它转千分之三
        assert(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));
        assert(IERC20(toToken).transfer(to, amountOutAdjust));

        reserve0 = newReserve0;
        reserve1 = newReserve1;
    }
}