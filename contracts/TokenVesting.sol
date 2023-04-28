// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IMintable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "hardhat/console.sol";

/**
 * @title TokenVesting
 */
contract TokenVesting is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintable;
    using SafeMath for uint256;

    uint256 public epoche = 1;
    uint256 public MAXIMUM_LOCK_PERIOD = 90 days;
    uint256 public epocheStartingTime = getCurrentTime();

    struct VestingSchedule {
        // beneficiary of tokens after they are released
        address beneficiary;
        // start time of the vesting period
        uint256 start;
        // end time of the vesting period
        uint256 end;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
        // amount of tokens burned
        uint256 burned;
    }

    // Address of Cruize token contract.
    IMintable public cruizeToken;
    // The ARMADA TOKEN!
    IMintable public armadaToken;

    mapping(address => VestingSchedule[]) private vestingSchedules;
    uint256 public vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    error ZERO_AMOUNT();
    error NOT_TRANSFERRED();
    error NOT_RELEASEABLE();
    error NOT_BENEFICIARY();
    error ALREADY_RELEASED();
    error NOT_ENOUGH_BALANCE();
    error NOT_SUFFICIENT_TOKENS();
    error NOT_ENOUGH_RELEASEABLE_AMOUNT();

    event ConvertToCruize(address indexed user, uint256 amount);
    event Vested(address account, uint256 amount, uint256 start, uint256 end);

    /**
     * @dev Creates a vesting contract.
     * @param _cruizeToken address of the Cruize token contract
     * @param _armadaToken address of the Armada token contract
     */
    function initialize(
        address _cruizeToken,
        address _armadaToken
    ) public initializer {
        // Check that the token address is not 0x0.
        require(_cruizeToken != address(0) || _armadaToken != address(0));
        // Set the token address.
        cruizeToken = IMintable(_cruizeToken);
        armadaToken = IMintable(_armadaToken);
        __Pausable_init();
        __Ownable_init();
    }

    /**
     * @notice Function will simply convert Cruize tokens to Armada Tokens
     * @param amount of cruize tokens to be converted
     */
    function convert(uint256 amount) public {
        if (amount == 0) revert ZERO_AMOUNT();
        cruizeToken.transferFrom(msg.sender, address(this), amount);
        armadaToken.mint(msg.sender, amount);
        emit ConvertToCruize(msg.sender, amount);
    }

    /**
     * @notice Calculates the next epoche
     * @return uint256 next epoche time
     */
    function nextEpoch() public view returns (uint256) {
        return
            block.timestamp -
            (block.timestamp % MAXIMUM_LOCK_PERIOD) +
            MAXIMUM_LOCK_PERIOD;
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function claim(uint256 _amount) external {
        address _beneficiary = msg.sender;

        if (_amount == 0) revert ZERO_AMOUNT();
        if (armadaToken.balanceOf(_beneficiary) < _amount)
            revert NOT_ENOUGH_BALANCE();

        uint256 _start = nextEpoch();
        uint256 _end = _start.add(MAXIMUM_LOCK_PERIOD);

        vestingSchedules[_beneficiary].push(
            VestingSchedule(_beneficiary, _start, _end, _amount, 0, 0)
        );

        emit Vested(_beneficiary, _amount, _start, _end);
    }

    /**
     * @notice Release vested amount of tokens.
     * @param index the vesting schedule identifier
     */
    function release(uint256 index) public nonReentrant {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender][
            index
        ];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        if (vestingSchedule.start > getCurrentTime()) revert NOT_RELEASEABLE();
        // only beneficiary and owner can release vested tokens
        if (!isBeneficiary) revert NOT_BENEFICIARY();
        if (vestingSchedule.amountTotal == vestingSchedule.released)
            revert ALREADY_RELEASED();
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        uint256 burnedAmount = vestingSchedule.amountTotal.sub(vestedAmount);
        // cannot release tokens, not enough vested tokens
        if (vestedAmount == 0) revert NOT_ENOUGH_RELEASEABLE_AMOUNT();

        vestingSchedule.released += vestedAmount;
        vestingSchedule.burned = burnedAmount;

        cruizeToken.transfer(msg.sender, vestedAmount);
        /// @note here we have to distribute the remaining armada tokens to the other users
        armadaToken.burn(msg.sender, vestingSchedule.amountTotal);

        if (burnedAmount > 0) cruizeToken.burn(burnedAmount);
    }

    /**
     * @dev Returns the number of vesting schedules associated to a beneficiary.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(
        address _beneficiary
    ) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }

    /**
     * @notice Returns the vesting schedule information for a given holder and index.
     * @return the vesting schedule structure information
     */
    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index
    ) external view returns (VestingSchedule memory) {
        return getVestingSchedule(holder, index);
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(
        address account,
        uint256 index
    ) external view returns (uint256) {
        VestingSchedule storage vestingSchedule = vestingSchedules[account][
            index
        ];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(
        address account,
        uint256 index
    ) public view returns (VestingSchedule memory) {
        return vestingSchedules[account][index];
    }

    /**
     * @dev Returns the last vesting schedule for a given holder address.
     */
    function getLastVestingScheduleForHolder(
        address holder
    ) external view returns (VestingSchedule memory) {
        uint256 length = vestingSchedules[holder].length;
        return vestingSchedules[holder][length - 1];
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal view returns (uint256) {
        // Retrieve the current time.
        uint256 currentTime = getCurrentTime();

        // If the current time is after the vesting period, all tokens are releasable,
        // minus the amount already released.
        if (currentTime >= vestingSchedule.end) {
            return vestingSchedule.amountTotal - vestingSchedule.released;
        }
        // Otherwise, some tokens are releasable.
        else {
            // Compute the number of full vesting periods that have elapsed.
            uint256 vestedSeconds = currentTime - vestingSchedule.start;
            // Compute the amount of tokens that are vested.
            uint256 vestedAmount = (vestingSchedule.amountTotal *
                vestedSeconds) / MAXIMUM_LOCK_PERIOD;
            return vestedAmount;
        }
    }

    /**
     * @dev Returns the current time.
     * @return the current timestamp in seconds.
     */
    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// ARMADA_SUPPLY = 1000 , CRUIZE_SUPPLY = 1000
// 100 ARMDA 100 CURIZE
// 50 ARMDA 50 CURIZE BURNED
// ARMADA_SUPPLY = 900 , CRUIZE_SUPPLY = 1000
// user# have 100 ARMADA
//
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
//  100 / 950 = 0.105 * 50 = 100 + 5.26  = 105.26 ARMADA
// -----------------------------------------------------
//                                        = 947 Armada