// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface USDC{
function faucet() external;
function approve(address spender, uint256 amount) external returns (bool);

}