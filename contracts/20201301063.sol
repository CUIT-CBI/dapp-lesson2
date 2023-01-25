// SPDX-License-Identifier: GPL-3.0

pragma solidity <0.9.0;

function createAndInitializePoolIfNecessary(
    address tokenA,
    address tokenB,
    uint24 fee,
    uint160 sqrtPriceX96
) external payable returns (address pool) {
    pool = IUniswapV3Factory(factory).getPool(tokenA, tokenB, fee);
 
    if (pool == address(0)) {
        pool = IUniswapV3Factory(factory).createPool(tokenA, tokenB, fee);
        IUniswapV3Pool(pool).initialize(sqrtPriceX96);
    } else {
        (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool).slot0();
        if (sqrtPriceX96Existing == 0) {
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
        }
    }
  function createPool(uint256 _amount0, uint256 _amount1) external {
        ERC20(tokenA).transferFrom(msg.sender, address(this), _amount0);
        ERC20(tokenB).transferFrom(msg.sender, address(this), _amount1);
        reserve0 = ERC20(tokenA).balanceOf(address(this));
        reserve1 = ERC20(tokenB).balanceOf(address(this));
        //liquidity = sqrt(amount0 * amount1)
        liquidity = sqrt(_amount0 * _amount1);

        _mint(msg.sender, liquidity);
    }

pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(tokenA, tokenB, fee))}());

constructor() {
    int24 _tickSpacing;
    (factory, tokenA, tokenB, fee, _tickSpacing) = IUniswapV3PoolDeployer(msg.sender).parameters();
    tickSpacing = _tickSpacing;
    maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
}

function initialize(uint160 sqrtPriceX96) external override {
    require(slot0.sqrtPriceX96 == 0, 'AI');
 
    int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
 
    (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());
 
    slot0 = Slot0({
        sqrtPriceX96: sqrtPriceX96,
        tick: tick,
        observationIndex: 0,
        observationCardinality: cardinality,
        observationCardinalityNext: cardinalityNext,
        feeProtocol: 0,
        unlocked: true
    });
 
    emit Initialize(sqrtPriceX96, tick);
}

function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes calldata data
) external override lock returns (uint256 amount0, uint256 amount1) {
    require(amount > 0);
    (, int256 amount0Int, int256 amount1Int) =
        _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(amount).toInt128()
            })
        );
 
    amount0 = uint256(amount0Int);
    amount1 = uint256(amount1Int);
 
    uint256 balance0Before;
    uint256 balance1Before;
    if (amount0 > 0) balance0Before = balance0();
    if (amount1 > 0) balance1Before = balance1();
    IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);
    if (amount0 > 0) require(balance0Before.add(amount0) <= balance0(), 'M0');
    if (amount1 > 0) require(balance1Before.add(amount1) <= balance1(), 'M1');
 
    emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
}

function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 amount
) external override lock returns (uint256 amount0, uint256 amount1) {

    (Position.Info storage position, int256 amount0Int, int256 amount1Int) =
        _modifyPosition(
            ModifyPositionParams({
                owner: msg.sender,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: -int256(amount).toInt128()
            })
        );
 
    amount0 = uint256(-amount0Int);
    amount1 = uint256(-amount1Int);
 
    if (amount0 > 0 || amount1 > 0) {
        (position.tokensOwed0, position.tokensOwed1) = (
            position.tokensOwed0 + uint128(amount0),
            position.tokensOwed1 + uint128(amount1)
        );
    }
 
    emit Burn(msg.sender, tickLower, tickUpper, amount, amount0, amount1);
}
struct AddLiquidityParams {
    address tokenA;     
    address tokenB;    
    uint24 fee;         
    address recipient;  
    int24 tickLower;   
    int24 tickUpper;    
    uint128 amount;     
    uint256 amount0Max; 
    uint256 amount1Max; 
}
 
function addLiquidity(AddLiquidityParams memory params)
    internal
    returns (
        uint256 amount0,
        uint256 amount1,
        IUniswapV3Pool pool
    )
{
    PoolAddress.PoolKey memory poolKey =
        PoolAddress.PoolKey({tokenA: params.tokenA, tokenB: params.tokenB, fee: params.fee});
 
   
    pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
 
    (amount0, amount1) = pool.mint(
        params.recipient,
        params.tickLower,
        params.tickUpper,
        params.amount,
        
        abi.encode(MintCallbackData({poolKey: poolKey, payer: msg.sender}))
    );
 
    require(amount0 <= params.amount0Max);
    require(amount1 <= params.amount1Max);
}
struct MintCallbackData {
    PoolAddress.PoolKey poolKey;
    address payer;         
}
 
/// @inheritdoc IUniswapV3MintCallback
function uniswapV3MintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata data
) external override {
    MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
    CallbackValidation.verifyCallback(factory, decoded.poolKey);
 
    
    if (amount0Owed > 0) pay(decoded.poolKey.tokenA, decoded.payer, msg.sender, amount0Owed);
    if (amount1Owed > 0) pay(decoded.poolKey.tokenB, decoded.payer, msg.sender, amount1Owed);
}

Slot0 memory _slot0 = slot0; // SLOAD for gas optimization

 
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) internal pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Incorrect reserves");
        uint256 inputAmountWithFee = inputAmount * 997; 
        uint256 a = inputAmountWithFee * outputReserve;
        uint256 b = (inputReserve * 1000) + inputAmountWithFee;
        return a / b;
    }
    function tokenAToTokenB(uint256 _inputAmount, uint256 _minTokens) public {
        uint256 getAmount = getAmountOfTokens(_inputAmount, reserve0, reserve1);
        require(getAmount >= _minTokens, "Incorrect output amount");

        reserve0 += _inputAmount;
        reserve1 -= getAmount;

        ERC20(tokenA).transferFrom(msg.sender, address(this), _inputAmount);
        ERC20(tokenB).transferFrom(msg.sender, address(this), getAmount);  
        
        reserve0 = ERC20(tokenA).balanceOf(address(this));
        reserve1 = ERC20(tokenB).balanceOf(address(this));   
    }    
    function tokenBToTokenA(uint256 _inputAmount, uint256 _minTokens) public {
        uint256 getAmount = getAmountOfTokens(_inputAmount, reserve1, reserve0);
        require(getAmount >= _minTokens, "Incorrect output amount");

        reserve1 += _inputAmount;
        reserve0 -= getAmount;

        ERC20(tokenB).transferFrom(msg.sender, address(this), _inputAmount);
        ERC20(tokenA).transferFrom(msg.sender, address(this), getAmount);  
        
        reserve0 = ERC20(tokenA).balanceOf(address(this));
        reserve1 = ERC20(tokenB).balanceOf(address(this));   
    }

    function _SwapByTokenA(uint amountAin) internal returns (uint amountBout) {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAin);
        amountBout = (_reserveB - (_reserveA * _reserveB) / (_reserveA + amountAin))  * 997 / 1000;   
        IERC20(tokenB).transfer(msg.sender, amountBout);
    }

    function _SwapByTokenB(uint amountBin) internal returns (uint amountAout) {
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBin);
        amountAout = (_reserveA - (_reserveA * _reserveB) / (_reserveB + amountBin)) * 997 / 1000;   
        IERC20(tokenA).transfer(msg.sender, amountAout);
    }

    function Swap(address token, uint amountIn) external {
        require(token == tokenA || token == tokenB, "invalid token address");
        if(token == tokenA) {
            _SwapByTokenA(amountIn);
        } else {
            _SwapByTokenB(amountIn);
        }
        _update();
    }
