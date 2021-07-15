// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

// Inheritance
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVault.sol";
import "./lib/NativeMetaTransaction.sol";

contract Vault is IVault, ReentrancyGuard, NativeMetaTransaction {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public vaultToken;

    uint256 public vestingPeriod;
    uint256 public vaultLimit;
    uint256 public interestRate;

    struct UserVault {
        uint256 amount;
        uint256 depositTime;
        uint256 vestingPeriodEnds;
        uint256 lastUpdated;
        uint256 claimedAmount;
        uint256 totalEarned;
    }

    mapping(address => UserVault[]) public userVault;

    uint256 private _totalSupply;
    uint256 private _totalDeposit;

    mapping(address => uint256) private _balances;
    
    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 reward);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _vaultToken,
            uint256 _vestingPeriod,
            uint256 _interestRate,
            uint256 _vaultLimit) public {
        vaultToken = IERC20(_vaultToken);
        vaultLimit = _vaultLimit.mul(1 ether);
        interestRate = _interestRate.add(100);
        vestingPeriod = _vestingPeriod.mul(1 days);
        _initializeEIP712('VaultV1');
    }

    /* ========== VIEWS ========== */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function totalDeposits() external view returns (uint256) {
        return _totalDeposit;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function getUserVaultInfo(address account) external view returns (UserVault[] memory) {
        return userVault[account];
    }

    function earned(address account) public view override returns (uint256) {
        UserVault[] memory userVaultData = userVault[account];
        uint256 claimableAmount = 0;

        for (uint256 i = 0; i < userVaultData.length; i++) {
            if (userVaultData[i].amount <= userVaultData[i].claimedAmount) continue;
            uint256 currentTime =
                block.timestamp > userVaultData[i].vestingPeriodEnds
                    ? userVaultData[i].vestingPeriodEnds
                    : block.timestamp;
            uint256 timeSinceLastClaim = currentTime.sub(userVaultData[i].lastUpdated);
            uint256 unlockedAmount = userVaultData[i].amount.mul(timeSinceLastClaim).div(vestingPeriod);
            claimableAmount = claimableAmount.add(unlockedAmount.mul(interestRate).div(100));
        }
        return claimableAmount;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 amount) external override nonReentrant {
        require(amount > 0, 'Cannot stake 0');
        require(_totalDeposit.add(amount) <= vaultLimit, 'Vault:stake:: vault limit exceeded');

        _totalSupply = _totalSupply.add(amount);
        _totalDeposit = _totalDeposit.add(amount);
        _balances[_msgSender()] = _balances[_msgSender()].add(amount);

        vaultToken.safeTransferFrom(_msgSender(), address(this), amount);

        UserVault[] storage userVaultData = userVault[_msgSender()];
        UserVault memory userVaultNewEntry =
            UserVault(amount, block.timestamp, block.timestamp.add(vestingPeriod), block.timestamp, 0, 0);
        userVaultData.push(userVaultNewEntry);

        emit Staked(_msgSender(), amount);
    }

    function claim() public override nonReentrant {
        if (_balances[msg.sender] > 0) {
            UserVault[] storage userVaultData = userVault[msg.sender];
            uint256 claimableAmount = 0;
            for (uint256 i = 0; i < userVaultData.length; i++) {
                if (userVaultData[i].amount <= userVaultData[i].claimedAmount) continue;
                uint256 currentTime =
                    block.timestamp > userVaultData[i].vestingPeriodEnds
                        ? userVaultData[i].vestingPeriodEnds
                        : block.timestamp;
                uint256 timeSinceLastClaim = currentTime.sub(userVaultData[i].lastUpdated);
                uint256 unlockedAmount = userVaultData[i].amount.mul(timeSinceLastClaim).div(vestingPeriod);

                if (currentTime == userVaultData[i].vestingPeriodEnds) {
                    unlockedAmount = userVaultData[i].amount.sub(userVaultData[i].claimedAmount);
                }

                claimableAmount = claimableAmount.add(unlockedAmount.mul(interestRate).div(100));
                userVaultData[i].claimedAmount = userVaultData[i].claimedAmount.add(unlockedAmount);
                userVaultData[i].totalEarned = userVaultData[i].totalEarned.add(
                    unlockedAmount.mul(interestRate).div(100)
                );
                _totalSupply = _totalSupply.sub(unlockedAmount);
                _balances[msg.sender] = _balances[msg.sender].sub(unlockedAmount);
                userVaultData[i].lastUpdated = currentTime;
            }
            vaultToken.safeTransfer(msg.sender, claimableAmount);
            emit Claimed(msg.sender, claimableAmount);
        }
    }

}