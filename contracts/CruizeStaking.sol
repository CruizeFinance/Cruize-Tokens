// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IMintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CruizeStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 time;
        uint256 amount;
        uint256 rewardDebt;
    }

    // Address of Cruize token contract.
    IERC20 cruizeToken;
    // The ARMADA TOKEN!
    IMintable public armadaToken;
    // armada per block
    uint256 armadaPerBlock;
    uint256 accArmadaPerShare;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IERC20 _cruize,
        IMintable _armada,
        uint256 _armadaPerBlock
    ) {
        cruizeToken = _cruize;
        armadaToken = _armada;
        armadaPerBlock = _armadaPerBlock;
    }

    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accArmadaPerShare).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                safeArmadaTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            cruizeToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(accArmadaPerShare).div(1e12);
        armadaToken.mint(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw ARMADA tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        uint256 pending = user.amount.mul(accArmadaPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeArmadaTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            cruizeToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(accArmadaPerShare).div(1e12);

        armadaToken.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // Safe armada transfer function, just in case if rounding error causes pool to not have enough Armada tokens.
    function safeArmadaTransfer(address _to, uint256 _amount) internal {
        armadaToken.safeArmadaTransfer(_to, _amount);
    }
}
