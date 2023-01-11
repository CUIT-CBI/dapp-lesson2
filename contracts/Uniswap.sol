// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IUniswapRouter.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IUniswapFactory.sol";
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import "./libraries/SafeMath.sol";


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
        ? (tokenA, tokenB)
        : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IUniswapFactory(factory).getPair(token0, token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        )
        .getReserves();
        (reserveA, reserveB) = tokenA == token0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }


    // 这个方法实现扣除百分之三的手续费用
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        //确认输入数额大于0
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        //确认储备量In和储备量Out大于0
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        //税后输入数额 = 输入数额 * 997
        uint256 amountInWithFee = amountIn.mul(997);
        //分子 = 税后输入数额 * 储备量Out
        uint256 numerator = amountInWithFee.mul(reserveOut);
        //分母 = 储备量In * 1000 + 税后输入数额
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        //输出数额 = 分子 / 分母
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        //确认输出数额大于0
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        //确认储备量In和储备量Out大于0
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        //分子 = 储备量In * 储备量Out * 1000
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        //分母 = 储备量Out - 输出数额 * 997
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        //输入数额 = (分子 / 分母) + 1
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        //确认路径数组长度大于2
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        //初始化数额数组
        amounts = new uint256[](path.length);
        //数额数组[0] = 输入数额
        amounts[0] = amountIn;
        //遍历路径数组,path长度-1
        for (uint256 i; i < path.length - 1; i++) {
            //(储备量In,储备量Out) = 获取储备(当前路径地址,下一个路径地址)
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            //下一个数额 = 获取输出数额(当前数额,储备量In,储备量Out)
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        //确认路径数组长度大于2
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        //初始化数额数组
        amounts = new uint256[](path.length);
        //数额数组最后一个元素 = 输出数额
        amounts[amounts.length - 1] = amountOut;
        //从倒数第二个元素倒叙遍历路径数组
        for (uint256 i = path.length - 1; i > 0; i--) {
            //(储备量In,储备量Out) = 获取储备(上一个路径地址,当前路径地址)
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            //上一个数额 = 获取输入数额(当前数额,储备量In,储备量Out)
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}


// 这里为部署的合约 这里为路由合约来操作工厂合约
contract uniswap is IUniswapV2Router {
    //布署时定义的常量工厂地址和weth地址
    address override public factory;
    address override public WETH;
    //修饰符:确保最后期限大于当前时间
    modifier ensure(uint256 deadline) {
        // solium-disable-next-line security/no-block-members
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        _;
    }

    //构造函数:传入工厂地址和weth地址
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    //退款方法
    receive() external payable {
        //断言调用者为weth合约地址
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        //如果配对不存在,则创建配对
        if (IUniswapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapFactory(factory).createPair(tokenA, tokenB);
        }
        //获取储备量reserve{A,B}
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
            factory,
            tokenA,
            tokenB
        );
        //如果储备reserve{A,B}==0
        if (reserveA == 0 && reserveB == 0) {
            //数量amount{A,B} = 期望数量A,B
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            //最优数量B = 期望数量A * 储备B / 储备A
            uint256 amountBOptimal = UniswapV2Library.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            //如果最优数量B <= 期望数量B
            if (amountBOptimal <= amountBDesired) {
                //确认最优数量B >= 最小数量B
                require(
                    amountBOptimal >= amountBMin,
                    "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
                );
                //数量amount{A,B} = 期望数量A, 最优数量B
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                //最优数量A = 期望数量A * 储备A / 储备B
                uint256 amountAOptimal = UniswapV2Library.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                //断言最优数量A <= 期望数量A
                assert(amountAOptimal <= amountADesired);
                //确认最优数量A >= 最小数量A
                require(
                    amountAOptimal >= amountAMin,
                    "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
                );
                //数量amount{A,B} = 最优数量A, 期望数量B
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    override
    ensure(deadline)
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    )
    {
        //获取数量A,数量B
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        //根据TokenA,TokenB地址,获取`pair合约`地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        //将数量为amountA的tokenA从msg.sender账户中安全发送到pair合约地址
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        //将数量为amountB的tokenB从msg.sender账户中安全发送到pair合约地址
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        //流动性数量 = pair合约的铸造方法铸造给to地址的返回值
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        //调用factory方法。
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        //将流动性数量从用户发送到pair地址(需提前批准)
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        //pair合约销毁流动性数量,并将数值0,1的token发送到to地址
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        //排序tokenA,tokenB
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        //按排序后的token顺序返回数值AB
        (amountA, amountB) = tokenA == token0
        ? (amount0, amount1)
        : (amount1, amount0);
        //确保数值AB大于最小值AB
        require(
            amountA >= amountAMin,
            "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
        );
        require(
            amountB >= amountBMin,
            "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
        );
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    override
    ensure(deadline)
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    )
    {
        //获取Token数量,ETH数量
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        //根据Token,WETH地址,获取`pair合约`地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        //将`Token数量`的token从msg.sender账户中安全发送到`pair合约`地址
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        //向`WETH合约`存款`ETH数量`的主币
        IWETH(WETH).deposit{value: amountETH}();
        //将`ETH数量`的`WETH`token发送到`pair合约`地址
        assert(IWETH(WETH).transfer(pair, amountETH));
        //流动性数量 = pair合约的铸造方法铸造给`to地址`的返回值
        liquidity = IUniswapV2Pair(pair).mint(to);
        //如果`收到的主币数量`>`ETH数量` 则返还`收到的主币数量`-`ETH数量`
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    /**
     * @dev 移除ETH流动性
     * @param token token地址
     * @param liquidity 流动性数量
     * @param amountTokenMin token最小数量
     * @param amountETHMin ETH最小数量
     * @param to to地址
     * @param deadline 最后期限
     * @return amountToken   token数量
     * @return amountETH   ETH数量
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) override public ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        //(token数量,ETH数量) = 移除流动性(token地址,WETH地址,流动性数量,token最小数量,ETH最小数量,当前合约地址,最后期限)
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        //将token数量的token发送到to地址
        TransferHelper.safeTransfer(token, to, amountToken);
        //从WETH取款ETH数量
        IWETH(WETH).withdraw(amountETH);
        //将ETH数量的ETH发送到to地址
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @dev 带签名移除流动性
     * @param tokenA tokenA地址
     * @param tokenB tokenB地址
     * @param liquidity 流动性数量
     * @param amountAMin 最小数量A
     * @param amountBMin 最小数量B
     * @param to to地址
     * @param deadline 最后期限
     * @param approveMax 全部批准
     * @param v v
     * @param r r
     * @param s s
     * @return amountA   数量A
     * @return amountB   数量B
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) override external returns (uint256 amountA, uint256 amountB) {
        //计算TokenA,TokenB的CREATE2地址，而无需进行任何外部调用
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        //如果全部批准,value值等于最大uint256,否则等于流动性
        uint256 value = approveMax ? type(uint256).max : liquidity;
        //调用pair合约的许可方法(调用账户,当前合约地址,数值,最后期限,v,r,s)
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        //(数量A,数量B) = 移除流动性(tokenA地址,tokenB地址,流动性数量,最小数量A,最小数量B,to地址,最后期限)
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    /**
     * @dev 带签名移除ETH流动性
     * @param token token地址
     * @param liquidity 流动性数量
     * @param amountTokenMin token最小数量
     * @param amountETHMin ETH最小数量
     * @param to to地址
     * @param deadline 最后期限
     * @param approveMax 全部批准
     * @param v v
     * @param r r
     * @param s s
     * @return amountToken   token数量
     * @return amountETH   ETH数量
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) override external returns (uint256 amountToken, uint256 amountETH) {
        //计算Token,WETH的CREATE2地址，而无需进行任何外部调用
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        //如果全部批准,value值等于最大uint256,否则等于流动性
        uint256 value = approveMax ? type(uint256).max : liquidity;
        //调用pair合约的许可方法(调用账户,当前合约地址,数值,最后期限,v,r,s)
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        //(token数量,ETH数量) = 移除ETH流动性(token地址,流动性数量,token最小数量,ETH最小数量,to地址,最后期限)
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) private {
        //遍历路径数组
        for (uint256 i; i < path.length - 1; i++) {
            //(输入地址,输出地址) = (当前地址,下一个地址)
            (address input, address output) = (path[i], path[i + 1]);
            //token0 = 排序(输入地址,输出地址)
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            //输出数量 = 数额数组下一个数额
            uint256 amountOut = amounts[i + 1];
            //(输出数额0,输出数额1) = 输入地址==token0 ? (0,输出数额) : (输出数额,0)
            (uint256 amount0Out, uint256 amount1Out) = input == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
            //to地址 = i<路径长度-2 ? (输出地址,路径下下个地址)的pair合约地址 : to地址
            address to = i < path.length - 2
            ? UniswapV2Library.pairFor(factory, output, path[i + 2])
            : _to;
            //调用(输入地址,输出地址)的pair合约地址的交换方法(输出数额0,输出数额1,to地址,0x00)
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
            .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) override external ensure(deadline) returns (uint256[] memory amounts) {
        //数额数组 ≈ 遍历路径数组((输入数额 * 997 * 储备量Out) / (储备量In * 1000 + 输入数额 * 997))
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        //确认数额数组最后一个元素>=最小输出数额
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        //将数量为数额数组[0]的路径[0]的token从调用者账户发送到路径0,1的pair合约
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        //私有交换(数额数组,路径数组,to地址)
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) override external ensure(deadline) returns (uint256[] memory amounts) {
        //数额数组 ≈ 遍历路径数组((储备量In * 储备量Out * 1000) / (储备量Out - 输出数额 * 997) + 1)
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        //确认数额数组第一个元素<=最大输入数额
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        //将数量为数额数组[0]的路径[0]的token从调用者账户发送到路径0,1的pair合约
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        //私有交换(数额数组,路径数组,to地址)
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) override external payable ensure(deadline) returns (uint256[] memory amounts) {
        //确认路径第一个地址为WETH
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        //数额数组 ≈ 遍历路径数组((msg.value * 997 * 储备量Out) / (储备量In * 1000 + msg.value * 997))
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        //确认数额数组最后一个元素>=最小输出数额
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        //将数额数组[0]的数额存款ETH到WETH合约
        IWETH(WETH).deposit{value: amounts[0]}();
        //断言将数额数组[0]的数额的WETH发送到路径(0,1)的pair合约地址
        assert(
            IWETH(WETH).transfer(
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        //私有交换(数额数组,路径数组,to地址)
        _swap(amounts, path, to);
    }


    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) override external ensure(deadline) returns (uint256[] memory amounts) {
        //确认路径最后一个地址为WETH
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        //数额数组 ≈ 遍历路径数组((储备量In * 储备量Out * 1000) / (储备量Out - 输出数额 * 997) + 1)
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        //确认数额数组第一个元素<=最大输入数额
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        //将数量为数额数组[0]的路径[0]的token从调用者账户发送到路径0,1的pair合约
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        //私有交换(数额数组,路径数组,当前合约地址)
        _swap(amounts, path, address(this));
        //从WETH合约提款数额数组最后一个数值的ETH
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        //将数额数组最后一个数值的ETH发送到to地址
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }


    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) override external ensure(deadline) returns (uint256[] memory amounts) {
        //确认路径最后一个地址为WETH
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        //数额数组 ≈ 遍历路径数组((输入数额 * 997 * 储备量Out) / (储备量In * 1000 + 输入数额 * 997))
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        //确认数额数组最后一个元素>=最小输出数额
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        //将数量为数额数组[0]的路径[0]的token从调用者账户发送到路径0,1的pair合约
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        //私有交换(数额数组,路径数组,当前合约地址)
        _swap(amounts, path, address(this));
        //从WETH合约提款数额数组最后一个数值的ETH
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        //将数额数组最后一个数值的ETH发送到to地址
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) override external payable ensure(deadline) returns (uint256[] memory amounts) {
        //确认路径第一个地址为WETH
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        //数额数组 ≈ 遍历路径数组((储备量In * 储备量Out * 1000) / (储备量Out - 输出数额 * 997) + 1)
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        //确认数额数组第一个元素<=msg.value
        require(
            amounts[0] <= msg.value,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        //将数额数组[0]的数额存款ETH到WETH合约
        IWETH(WETH).deposit{value: amounts[0]}();
        //断言将数额数组[0]的数额的WETH发送到路径(0,1)的pair合约地址
        assert(
            IWETH(WETH).transfer(
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        //私有交换(数额数组,路径数组,to地址)
        _swap(amounts, path, to);
        //如果`收到的主币数量`>`数额数组[0]` 则返还`收到的主币数量`-`数额数组[0]`
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) override public pure returns (uint256 amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    // **** LIBRARY FUNCTIONS ****
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) override public pure returns (uint256 amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) override public pure returns (uint256 amountIn) {
        return UniswapV2Library.getAmountOut(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
    override
    public
    view
    returns (uint256[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
    override
    public
    view
    returns (uint256[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}
