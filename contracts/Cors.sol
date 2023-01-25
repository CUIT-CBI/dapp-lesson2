// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";

library Math {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract Cors {
    //管理员地址，也就是部署该合约的地址和手续费收取地址
    address admin;

    FT public t1;
    FT public t2;
    FT public Lpt;
    uint256 t1N;
    uint256 t2N;
    uint256 ratio;
    uint256 public LpN;

    bool private bigLeft;

    mapping(address => uint256) public userToken;

    constructor(
        FT _Lpt,
        FT _t1,
        FT _t2
    ) {
        admin = msg.sender;
        t1 = _t1;
        t2 = _t2;
        Lpt = _Lpt;
    }

    //初始化交易池
    function _start(uint256 _t1N, uint256 _t2N) public payable {
        require(msg.sender == admin, "Only Admin Can Call This Function");
        t1N = _t1N;
        t2N = _t2N;
        LpN = t1N * t2N;
        if (_t1N > _t2N) {
            ratio = _t1N / t2N;
            bigLeft = true;
        } else {
            ratio = _t2N / t1N;
            bigLeft = false;
        }
        t1.transferFrom(msg.sender, address(this), _t1N);
        t2.transferFrom(msg.sender, address(this), _t2N);
    }

    //增加流动性
    function addLpN(uint256 _t1N, uint256 _t2N)
        public
        payable
        returns (uint256)
    {
        require(_t1N > 0 && _t2N > 0, "The deposited money cannot be empty!");

        t1N += _t1N;
        t2N += _t2N;
        LpN = t1N * t2N;

        uint256 userTotal = _t1N * _t2N;
        userToken[msg.sender] += Math.sqrt(userTotal);

        t1.transferFrom(msg.sender, address(this), _t1N);
        t2.transferFrom(msg.sender, address(this), _t2N);

        Lpt.transfer(msg.sender, Math.sqrt(userTotal));
        return Math.sqrt(userTotal);
    }

    //移出流动性
    function removeLpN(uint256 _Lpt) public payable {
        require(_Lpt > 0, "The Deposited Token Can't Be Empty!");
        require(userToken[msg.sender] > 0, "You are not providing LpN!");

        uint256 _t1N;
        uint256 _t2N;
        if (bigLeft == true) {
            _t2N = _Lpt / (Math.sqrt(ratio));
            _t1N = _t2N * ratio;
        } else {
            _t1N = _Lpt / (Math.sqrt(ratio));
            _t2N = _t1N * ratio;
        }

        t1N -= _t1N;
        t2N -= _t2N;
        LpN = t1N * t2N;

        userToken[msg.sender] -= _Lpt;

        Lpt.transferFrom(msg.sender, address(this), _Lpt);

        t1.transfer(msg.sender, _t1N);
        t2.transfer(msg.sender, _t2N);
    }

    //t1 -> t2
    function tradeByt1(uint256 _t1N) public payable returns (uint256) {
        uint256 _t2N;
        if (bigLeft == true) {
            _t2N = _t1N / ratio;
        } else {
            _t2N = _t1N * ratio;
        }

        require(
            _t2N < t2.balanceOf(address(this)),
            "You Dont't Have Enough Token"
        );
        //手续费
        uint256 premium = (_t2N * 3) / 1000;

        t1N += _t1N;
        t2N -= _t2N;

        LpN = t1N * t2N;

        t1.transferFrom(msg.sender, address(this), _t1N);
        t2.transfer(msg.sender, _t2N - premium);
        t2.transfer(admin, premium);
        return _t2N - premium;
    }

    //t2 -> t1
    function tradeByt2(uint256 _t2N) public payable returns (uint256) {
        uint256 _t1N;
        if (bigLeft == true) {
            _t1N = _t2N * ratio;
        } else {
            _t1N = _t2N / ratio;
        }

        require(_t1N < t1.balanceOf(address(this)), "Tokens are not enough!");
        //手续费
        uint256 premium = (_t1N * 3) / 1000;

        t1N -= _t1N;
        t2N += _t2N;

        LpN = t1N * t2N;

        t2.transferFrom(msg.sender, address(this), _t2N);
        t1.transfer(msg.sender, _t1N - premium);
        t1.transfer(admin, premium);
        return _t1N - premium;
    }
}
