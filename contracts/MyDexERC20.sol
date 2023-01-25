pragma solidity =0.5.16;
//主要参考资料：https://blog.csdn.net/zhoujianwei/article/details/124893118
import './interfaces/IMyDexERC20.sol';
import './libraries/SafeMath.sol';

contract MyDexERC20 is IMyDexERC20 {
    using SafeMath for uint;

    string public constant name = 'FengYihan Dex';      //我的姓名拼音；
    string public constant symbol = '2020131148';       //我的学号；
    uint8 public constant decimals = 18;

    uint  public totalSupply;       //token的总供应量;

    mapping(address => uint) public balanceOf;      //地址与余额之间的映射;
    mapping(address => mapping(address => uint)) public allowance;      //授权交易与授权交易数额之间的映射;

    bytes32 public DOMAIN_SEPARATOR;        //EIP712所规定的DOMAIN_SEPARATOR值，会在构造函数中进行赋值;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;       
    /*
    EIP712所规定的TYPEHASH，这里直接使用对
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    进行硬编码所得到的值.
    */
    mapping(address => uint) public nonces;     //地址与nonce之间的映射;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;       //当前运行的链的标识;
        assembly {
            chainId := chainid      //获取链的标识；
        }
        DOMAIN_SEPARATOR = keccak256(       //对DOMAIN_SEPARATOR进行赋值；
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {       //向某个地址发送一定数量的token;
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {     //销毁某个地址的所持有的token;
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {     //修改allowance对应的映射;
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint value) external returns (bool) {     //授权；
        _approve(msg.sender, spender, value);
        return true;
    }

    /*
    线下签名授权。授权在线下签名进行，签名信息可以在执行接收转账交易时提交到链上，让授权和转账在一笔交易里完成。
    */
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'MyDex: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'MyDex: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {      //简单实现转账；
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint value) external returns (bool) {     //转账，将token从拥有者转到to地址；
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {       //授权转账。
    //在执行该方法之前，需要通过approve授权方法或者permit授权方法进行授权
        if (allowance[from][msg.sender] != uint(-1)) {      //确认msg.sender在allowance中是否有值,
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);       //如果有值就减去对应的金额;
        }
        _transfer(from, to, value);
        return true;
    }
}
