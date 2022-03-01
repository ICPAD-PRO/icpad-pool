// contracts/interfaces/IPoolFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStake {

    function getLevel(address _user) external view returns (uint level);
}
