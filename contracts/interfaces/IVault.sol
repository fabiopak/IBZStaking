// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IVault {
    // Views
    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function claim() external;
}
