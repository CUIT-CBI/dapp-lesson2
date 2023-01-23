// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Pair.sol';
import './SwapERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

contract SwapPair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;//��С������
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           
    uint112 private reserve1;           
    uint32  private blockTimestampLast; 

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;//�㶨�˻�ֵ

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        // ���� factory ��ַ
        factory = msg.sender;
    }

    //�ʽ��״̬
    function getReserves() public view returns (
        uint112 _reserve0, //token0���ʽ������
        uint112 _reserve1, //token1���ʽ������
        uint32 _blockTimestampLast//ʱ������ϴθ��¿��ʱ��
    ) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }


    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

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

    // ֻ���ں�Լ�����ʱ����ܵ���һ�δ�������token�ĵ�ַ
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'forbidden'); // ����ַ
        token0 = _token0;
        token1 = _token1;
    }

    //�����ʽ��״̬
    function _update(
        uint balance0, // token0 �����
        uint balance1, // token1 �����
        uint112 _reserve0, // token0 ���ʽ�ؿ������
        uint112 _reserve1 // token1 ���ʽ�ؿ������
    ) private {
        //��Ҫ����token��������uint112������
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'overflow');
        //����ʱ���ֻȡ32λ
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        //����ʱ���timeElapsed
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    //������
    //_mintFeeʵ������Ӻ��Ƴ������Ե�ʱ��,��feeto��ַ����������
    function _mintFee(
        uint112 _reserve0, //token0���ʽ�ؿ������
        uint112 _reserve1 //token1���ʽ�ؿ������
    ) private returns (
        bool feeOn//�Ƿ���������
    ) {
        //��ȡ�����ѽ��յ�ַfeeTo
        address feeTo = IUniswapV2Factory(factory).feeTo();
        //�����ַ��Ϊ0���������ѽ���
        feeOn = feeTo != address(0);
        uint _kLast = kLast; 
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    //�ṩ������
    function mint(
        address to//LP���յ�ַ
    ) external lock returns (
        uint liquidity//LP����
    ) {
        //��ȡ��¼token���
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
        //��ȡ���ҵ����balance0��balance1
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        //��ȡ�û���Ѻ���
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        //����������
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            // LP �������� liquidity = (amount0 * amount1)**2 - MINIMUM_LIQUIDITY
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            // ��ȫ0��ַ��������Ϊ MINIMUM_LIQUIDITY �� LP ����
           _mint(address(0), MINIMUM_LIQUIDITY); 
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'imsuffucient_liquidity_minted');
        //��to��ַ��������Ϊliquidity��������
        _mint(to, liquidity);

        //���¿��
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Mint(msg.sender, amount0, amount1);
    }


    //�Ƴ�������
    function burn(
        address to//�ʲ����յ�ַ
    ) external lock returns (
        uint amount0, //��ȡtoken0������
        uint amount1//��ȡtoken1������
    ) {
        // ��ȡ��¼��� _reserve0��_reserve1
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // ��ȡ _token0��_token1
        address _token0 = token0;                                
        address _token1 = token1;     
        //��ȡ�������balance0,balance1                           
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        //��ȡliquidity������
        uint liquidity = balanceOf[address(this)];
        //����������
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; 

        amount0 = liquidity.mul(balance0) / _totalSupply; 
        amount1 = liquidity.mul(balance1) / _totalSupply; 

        require(amount0 > 0 && amount1 > 0, 'imsuffucient_liquidity_burned');
        //����liquidity������LP����
        _burn(address(this), liquidity);
        //ת��
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        //�������
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        //���¿��
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Burn(msg.sender, amount0, amount1, to);
    }

    //ʵ�ֽ��׹���
    function swap(
        uint amount0Out,//Ԥ�ڻ�õ�token0����
        uint amount1Out,//Ԥ�ڻ�õ�token1����
        address to,//�ʲ����յ�ַ
        bytes calldata data//�������������
    ) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'insufficient_output_amount');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'insufficient_liquidity');

        uint balance0;
        uint balance1;
        { 
        address _token0 = token0;   
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'invalid_to');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); 
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); 
        //���data.length>0,ִ�������
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        //��ȡtoken���
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'insufficient_input_amount');
        { 
            // ��Ҫ����֮��� K ֵ���ܱ�С
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= 
            uint(_reserve0).mul(_reserve1).mul(1000**2), 'k');
        }
        //���¿��
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    //��ƽ�⺯��
    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        // �����ڿ�� reserve0 �Ĵ��� _token0 ���͵� to ��ַ
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        // �����ڿ�� reserve1 �Ĵ��� _token1 ���͵� to ��ַ
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    //���¿��
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)), 
            IERC20(token1).balanceOf(address(this)), 
            reserve0, reserve1
        );
    }
}
