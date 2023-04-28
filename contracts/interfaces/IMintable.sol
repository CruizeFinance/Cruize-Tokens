// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMintable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function safeArmadaTransfer(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function mint(address to,uint256 amount) external;
    function burn(uint256 amount) external;
    function burn(address to,uint256 amount) external;
    function setMinter(address _minter, bool _isActive) external;
    function isMinter(address _account) external returns (bool);
}