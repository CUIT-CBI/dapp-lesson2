// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Factory.sol";
import "./Pair.sol";
import "./libraries/UniswapV2Library.sol";
import "./FT.sol";
contract Router{
    address public factory; //工厂地址
     modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }
    constructor(address _factory) public {
        factory = _factory;
    }
    
     function _addLiquidity(
        address tokenA,// A地址
        address tokenB,// B地址
        uint amountADesired, // A的填充量
        uint amountBDesired, // B的填充量
        uint amountAMin,     // A的填充量最小值
        uint amountBMin      // B的填充量最小值
    ) private returns (uint amountA, uint amountB) {
        // 如果不存在这个交易对，那么新建一个
        if (Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            Factory(factory).createPair(tokenA, tokenB);
        }
        // 获取当前池子A,B的储备量
        (uint reserveA, uint reserveB,) = Pair(Factory(factory).getpair(tokenA,tokenB)).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            // 新建的池子，直接填充
            (amountA, amountB) = (amountADesired, amountBDesired);
        } 
        else {
            // 如果两个储备量不为0，需要根据当前的价格/比例去新增流动性
            // 按A的比例填充 B的数量
            // AA/BB = A/B  -->  AA = BB*(A/B)
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            // amountBMin <= amountBOptimal <= amountBDesired
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } 
            else {
                // 按B的比例填充 A的数量
                // BB/AA = B/A  -->  BB = AA*(B/A)
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // 返回值：A,B 数量及得到的凭证数量
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external  ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        // 返回值：A,B 数量及得到的凭证数量
        // 调用_addLiquidity，计算需要打入的 A,B 数量
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        // 获取 pair 的地址
        address pair = Factory(factory).getpair(tokenA,tokenB);
        // msg.sender 往 pair 打入 amount 的 A 或者 B
        FT(tokenA).transferFrom(msg.sender, pair, amountA);
        FT(tokenB).transferFrom(msg.sender, pair, amountB);
        // pair 给 to 发 liquidity 数量的凭证, 并且 pair 增发 liquidity 的 lp
        liquidity = Pair(pair).mint(to);
    }

 // 移除流动性，该方法需要先将lp代币授权给路由合约，才能代扣lp
    // 返回值：amountA，amountB
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = Factory(factory).getPair(tokenA,tokenB);
        // 把msg.sender的lp还回去pair地址
        Pair(pair).transferFrom(msg.sender, pair, liquidity);
        // 调用pair的burn方法， 内部会将两个币的数量转给to, 返回值就是两个代币的输出数量
        (uint amount0, uint amount1) = Pair(pair).burn(to);
        // 通过排序确认两个amountA/B
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
     function _swap(
        uint[] memory amounts, 
        address[] memory path, 
        address _to
    ) private 
    {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            /**
             因为Factory里，tokenA和tokenB的地址从小到大排列。
             创建Pair的时候，也是token0 和 token1的地址也是从小到大排列。
             Pair内的swap函数的参数列表中(amount0Out 和 amount1Out) 是和 token0 和 token1 对应
             所以需要排序，确定 amountOut 对应的是 token0 还是 token1
             */
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            // output 地址对应的 amountOut
            // amount0Out, amount1Out 对应的值是 （0或amountOut）
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? Factory(factory).getpair(output, path[i + 2]) : _to;
            // IUniswapV2Pair 调用 swap函数
            Pair(Factory(factory).getpair(input,output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // 输入精确的token,换取另一个token(输出量不确定)
    function swapExactTokensForTokens(
        uint amountIn,// 输入金额
        uint amountOutMin,// 最小输入金额
        address[] calldata path,//交易路径
        address to,// 接收地址
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        // 获取AmountsOut列表
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 需要满足计算得来最终输出量大于等于最小输出金额
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 先将amounts[0]入金额转入第一个pair
        // msg.sender 给 UniswapV2Library.pairFor(factory, path[0], path[1]) 转数量 amounts[0] 的 path[0]
        FT(path[0]).transferFrom(msg.sender,Factory(factory).getpair(path[0],path[1]), amounts[0]);
        // 调用内部_swap方法
        _swap(amounts, path, to);
    }

}