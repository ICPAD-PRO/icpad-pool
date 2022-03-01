// contracts/interfaces/IPoolFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPoolFactory {
    event CreatePool(
        uint32 indexed id,
        address indexed assetManager,
        address poolToken,
        address quoteToken,
        uint256 amount,
        uint256 rate,
        uint256 units
    );
    event Swap(
        uint32 indexed id,
        address indexed taker,
        uint256 swapAmount,
        address quoteToken,
        uint256 amount
    );
    event Close(uint32 indexed id);

    event Claim(uint32 indexed id, address indexed taker, uint256 amount);

    function create(
        string memory _name,
        address _poolToken,
        address _quoteToken,
        uint256 _amount,
        uint256 _rate,
        uint256 _units,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _whiteListTime,
        address[] memory _takers,
        uint256[] memory _allowanceAmounts,
        uint256 _globalAllowance
    ) external;

    function swap(uint32 _id, uint256 _amount) external;

    function close(uint32 _id) external;

    function claim(uint32 _id) external;
}
