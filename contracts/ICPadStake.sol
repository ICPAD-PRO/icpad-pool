// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MConst.sol";
import "./interfaces/IStake.sol";

pragma experimental ABIEncoderV2;

contract ICPadStake is Ownable, MConst, IStake {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PoolInfo {
        IERC20 token;
        uint256 startBlock;
        uint256 bonusEndBlock;
    }

    struct UserTx {
        uint256 index;
        uint256 amount;
        uint256 releaseTimestamp;
        bool complete;
    }

    PoolInfo public poolInfo;
    mapping(address => uint256) public userInfo;
    mapping(address => uint256) userTxIndex;
    mapping(address => UserTx[]) public userTxs;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Release(address indexed user, uint256 amount);

    constructor(
        IERC20 _token,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        uint256 lastRewardBlock =
        block.number > _startBlock ? block.number : _startBlock;
        require(_bonusEndBlock > lastRewardBlock, "invalid bonusEndBlock");
        poolInfo = PoolInfo({
        token : _token,
        startBlock : _startBlock,
        bonusEndBlock : _bonusEndBlock
        });
    }

    function deposit(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        require(block.number >= pool.startBlock, "pool not start");
        require(block.number <= pool.bonusEndBlock, "pool end");
        pool.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        userInfo[msg.sender] = userInfo[msg.sender].add(_amount);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(userInfo[msg.sender] >= _amount, "invalid withdraw amount");
        uint256 index = userTxIndex[msg.sender] + 1;
        userTxIndex[msg.sender] = index;
        uint256 _releaseTimestamp = getReleaseTimestamp(address(msg.sender));
        userTxs[msg.sender].push(
            UserTx(
            {
            index : index,
            amount : _amount,
            releaseTimestamp : _releaseTimestamp,
            complete : false
            }));
        userInfo[msg.sender] = userInfo[msg.sender].sub(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function release(uint256 _index) external {
        require(userTxIndex[msg.sender] >= _index, "invalid index");
        UserTx storage tx = userTxs[msg.sender][_index];
        require(tx.complete == false, "complete state error");
        require(block.timestamp > tx.releaseTimestamp, "invalid releaseTimestamp");
        poolInfo.token.safeTransfer(address(msg.sender), tx.amount);
        tx.complete = true;
        emit Release(msg.sender, tx.amount);
    }

    function getLevel(address _user) public override view returns (uint level){
        uint256 userStakeAmount = userInfo[_user];
        if (userStakeAmount >= GENESIS_AMOUNT) {
            level = GENESIS_LEVEL;
        } else if (userStakeAmount >= LEGEND_AMOUNT && userStakeAmount < GENESIS_AMOUNT) {
            level = LEGEND_LEVEL;
        } else if (userStakeAmount >= EPIC_AMOUNT && userStakeAmount < LEGEND_AMOUNT) {
            level = EPIC_LEVEL;
        } else if (userStakeAmount >= APPRENTICE_AMOUNT && userStakeAmount < EPIC_AMOUNT) {
            level = ELITE_LEVEL;
        } else if (userStakeAmount > 0 && userStakeAmount < APPRENTICE_AMOUNT) {
            level = APPRENTICE_LEVEL;
        } else {
            level = NONE_LEVEL;
        }
    }

    function getTxs(address _user) external view returns (UserTx[] memory txs){
        txs = userTxs[_user];
        return txs;
    }

    function getReleaseTimestamp(address _user) public view returns (uint256 releaseTimestamp){
        uint level = getLevel(_user);
        if (level == GENESIS_LEVEL) {
            releaseTimestamp = block.timestamp + GENESIS_TIME;
        } else if (level == LEGEND_LEVEL) {
            releaseTimestamp = block.timestamp + LEGEND_TIME;
        } else if (level == EPIC_LEVEL) {
            releaseTimestamp = block.timestamp + EPIC_TIME;
        } else if (level == ELITE_LEVEL) {
            releaseTimestamp = block.timestamp + ELITE_TIME;
        } else if (level == APPRENTICE_LEVEL) {
            releaseTimestamp = block.timestamp + APPRENTICE_TIME;
        }
        return releaseTimestamp;
    }
}
