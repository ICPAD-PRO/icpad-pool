// contracts/PoolFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IStake.sol";

contract PoolFactory is Initializable, IPoolFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct SwapPool {
        string name;
        address poolToken;
        address payable assetManager;
        uint32 startTime;
        uint32 whiteListEndTime;
        uint32 claimTime;
        uint256 tokenRate;
        address quoteToken;
        uint256 restAmount;
        uint256 units;
        address[] whiteList;
        uint256 hardCap;
        uint256 claimedAmountSum;
    }

    mapping(uint32 => SwapPool) public swapPools;
    mapping(uint32 => mapping(address => uint256)) swappedAmounts;
    mapping(uint32 => mapping(address => uint256)) allowanceAmounts;
    mapping(uint32 => mapping(address => uint256)) public claimedAmounts;

    uint32 public poolCnt;
    mapping(address => uint256) public creators;
    IStake private stake;

    constructor(
        IStake _stake
    ) public {
        stake = _stake;
    }

    function initialize(address[] memory _creators) public initializer {
        for (uint256 i = 0; i < _creators.length; i++) {
            creators[_creators[i]] = 1;
        }
    }

    function create(
        string memory _name,
        address _poolToken,
        address _quoteToken,
        uint256 _amount,
        uint256 _rate,
        uint256 _units,
        uint32 _startTime,
        uint32 _claimTime,
        uint32 _whiteListEndTime,
        address[] memory _whiteList,
        uint256[] memory _allowanceAmounts,
        uint256 _hardCap
    ) public override {
        require(creators[msg.sender] == 1, "check creator");
        require(_amount > 0, "check create pool amount");
        require(_rate > 0, "check create pool amount");
        require(_units > 0, "check create pool amount");
        require(_startTime < _claimTime, "check create pool time");
        require(_claimTime > block.timestamp, "check end time");
        require(_hardCap <= _amount, "check bound amount");
        require(
            _whiteList.length == _allowanceAmounts.length,
            "check whiteList length"
        );

        uint256 setAllowanceSum = 0;
        for (uint256 i = 0; i < _whiteList.length; i++) {
            setAllowanceSum = setAllowanceSum.add(_allowanceAmounts[i]);
            allowanceAmounts[poolCnt][_whiteList[i]] = _allowanceAmounts[i];
        }
        require(
            setAllowanceSum <= _hardCap,
            "check bound amounts"
        );

        // transfer erc20 token from maker
        IERC20(_poolToken).safeTransferFrom(msg.sender, address(this), _amount);

        swapPools[poolCnt] = SwapPool({
        name : _name,
        poolToken : _poolToken,
        quoteToken : _quoteToken,
        assetManager : msg.sender,
        tokenRate : _rate,
        restAmount : _amount,
        startTime : _startTime,
        claimTime : _claimTime,
        whiteListEndTime : _whiteListEndTime,
        units : _units,
        whiteList : _whiteList,
        hardCap : _hardCap,
        claimedAmountSum : 0
        });

        emit CreatePool(poolCnt, msg.sender, _poolToken, _quoteToken, _amount, _rate, _units);

        poolCnt++;
    }

    function setWhiteList(uint32 _pid, address[] memory _whiteList, uint256[] memory _allowanceAmounts) public {
        require(creators[msg.sender] == 1, "check creator");
        require(
            _whiteList.length == _allowanceAmounts.length,
            "check taker length"
        );
//        uint256 setAllowanceSum = 0;
//        SwapPool memory _pool = swapPools[_pid];
        for (uint256 i = 0; i < _whiteList.length; i++) {
//            setAllowanceSum = setAllowanceSum.add(_allowanceAmounts[i]);
            allowanceAmounts[_pid][_whiteList[i]] = _allowanceAmounts[i];
        }
//        require(
//            setAllowanceSum <= _pool.restAmount,
//            "check bound amounts"
//        );
//        _pool.whiteList = _whiteList;
    }

    function swap(uint32 _pid, uint256 _amount) public override {
        require(_amount > 0, "check value, value must be gt 0");

        SwapPool storage _pool = swapPools[_pid];
        // check pool exist
        require(_pool.claimTime > 0, "check pool exists");
        require(block.timestamp > _pool.startTime, "check pool start time");
        // check end time
        require(block.timestamp < _pool.claimTime, "check before end time");

        uint256 _order = _amount.mul(_pool.tokenRate).div(_pool.units);
        require(_order > 0, "check taker amount");
        require(_order <= _pool.restAmount, "check left token amount");
        // check taker limit
        require(_order <= allowance(_pid, msg.sender), "check taker limit");

        updateSwapped(_pid, msg.sender, _order);

        _pool.restAmount = _pool.restAmount.sub(_order);

        // transfer  assetManager
        IERC20(_pool.quoteToken).safeTransferFrom(msg.sender, _pool.assetManager, _amount);
        emit Swap(_pid, msg.sender, _amount, _pool.quoteToken, _order);
    }

    function close(uint32 _id) public override {
        SwapPool storage _pool = swapPools[_id];

        require(_pool.claimTime > 0, "check pool exists");
        require(_pool.assetManager == msg.sender, "check assetManager owner");

        _pool.startTime = 0;
        _pool.claimTime = 0;

        IERC20(_pool.poolToken).safeTransfer(_pool.assetManager, _pool.restAmount);

        emit Close(_id);
    }

    function claim(uint32 _id) public override {
        SwapPool storage _pool = swapPools[_id];

        require(block.timestamp > _pool.claimTime, "check pool closed");
        uint256 amount = swappedAmounts[_id][msg.sender];
        require(
            claimedAmounts[_id][msg.sender] < amount,
            "check claim amounts"
        );

        claimedAmounts[_id][msg.sender] = amount;
        IERC20(_pool.poolToken).safeTransfer(msg.sender, amount);
        _pool.claimedAmountSum = _pool.claimedAmountSum.add(amount);
        emit Claim(_id, msg.sender, amount);
    }

    function waitingClaim(uint32 _id) public view returns (uint256) {
        return
        swappedAmounts[_id][msg.sender] - claimedAmounts[_id][msg.sender];
    }

    function whiteList(uint32 _id) public view returns (address[] memory) {
        SwapPool storage _pool = swapPools[_id];
        return _pool.whiteList;
    }

    function allowance(uint32 _id, address _addr)
    public
    view
    returns (uint256)
    {
        SwapPool storage _pool = swapPools[_id];
        if (block.timestamp > _pool.whiteListEndTime && stake.getLevel(_addr) > 0) {
            return _pool.restAmount;
        }
        return allowanceAmounts[_id][_addr].sub(swappedAmounts[_id][_addr]);
    }

    function updateSwapped(
        uint32 _id,
        address _addr,
        uint256 _amount
    ) internal {
        SwapPool storage _pool = swapPools[_id];

        uint256 newAmount = swappedAmounts[_id][_addr].add(_amount);
        if (_pool.hardCap != 0) {
            if (_pool.whiteList.length == 0) {
                // newAmount <= boundAmount
                require(newAmount <= _pool.hardCap, "allowance limit");
            } else {
                require(
                    newAmount <= allowanceAmounts[_id][_addr],
                    "allowance limit"
                );
            }
        }
        swappedAmounts[_id][_addr] = newAmount;
    }

    function info0() public view returns (uint256, uint32) {
        return (block.timestamp, swapPools[0].startTime);
    }

    function version() public pure returns (uint256) {
        return 5;
    }
}
