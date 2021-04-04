// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/math/Math.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// Inheritance
// import "./RewardsDistributionRecipient.sol";
// import "./Pausable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
interface IERC20Burnable is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}


contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

abstract contract RewardsDistributionRecipient is Owned {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) virtual external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// based on synthetix
contract DaiPool is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    // using ERC20Burnable for IERC20;
    // using SafeERC20 for IERC20;

    // ========== STATE VARIABLES ========== //

    IERC20Burnable public rewardsToken; // the reward token
    IERC20 public stakingToken; // the staking token
    uint256 public periodFinish = 0; // when staking ends
    uint256 public rewardRate = 0; // rewards per second distributed
    uint256 public rewardsDuration = 365 days; // default lifetime of the staking contract
    uint256 public lastUpdateTime; // last time rewards info has been updated
    uint256 public rewardPerTokenStored;  // amount of rewards earned per token staked 

    mapping(address => uint256) public userRewardPerTokenPaid; // amount of rewards the user was paid for each of their tokens 
    mapping(address => uint256) public rewards; // amount of unclaimed rewards for each staker

    bool public stopped;

    uint256 private _totalSupply; // total amount of stakingToken 
    mapping(address => uint256) private _balances; // amount of stakingToken for each address

    // ========== CONSTRUCTOR ========== //

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _stakingToken,
        address _rewardsToken
    ) Owned(_owner) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20Burnable(_rewardsToken);
        rewardsDistribution = _rewardsDistribution; // the wallet that provides the rewards 
    }

    // ========== VIEWS ========== //

    // returns total supply of staked tokens
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    // returns account's balance of staked tokens
    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    // returns the last time that applies for distributing rewards
    // the staking contract uses the current block time (block.timestamp) for calculating rewards, up until the duration of the staking contract has ended (periodFinish) 
    function lastTimeRewardApplicable() override public view returns (uint256) { 
        return Math.min(block.timestamp, periodFinish);
    }

    // returns the amount of rewards that will be distributed per token
    function rewardPerToken() override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        // to get the current rewards per token, add the last rewards per token calculated at the lastUpdateTime (rewardsPerkTokenStored) and add the rewards per token for the time between lastUpdateTime and the current time (astTimeRewardApplicable()) 
        // lastTimeRewardApplicable().sub(lastUpdateTime) = time between lastUpdateTime and the current time (astTimeRewardApplicable())
        // lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate) = rewards generated over this time period
        // lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18) = rewards generated over this time period to 18 decimals
        // lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply) = rewards generated over this time period per token staked
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    // returns the amount of rewards earned by the account
    // rewardPerToken().sub(userRewardPerTokenPaid[account]) gives you the new rate at which the account was earning rewards based on the last time the account was paid its rewards
    function earned(address account) override virtual public view returns (uint256) {
        return _balances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    // returns the amount of rewards being distributed over the rewardsDuration
    function getRewardForDuration() override external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    // ========== MUTATIVE FUNCTIONS ========== //

    // allows a user to stake some amount of tokens for rewards
    // crucially updates the rewards data before processing the staking operation
    // nonReentrant prevents this function from being called again in the same transaction. This stops malicious and/or untrusted actors or buggy code from manipulating the contract's invariants
    function stake(uint256 amount) override external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(periodFinish > 0, "Stake period not started yet");
        require(amount > 0, "Cannot stake 0");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        stakingToken.transferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    // allows a user to withdraw some amount of their staked tokens 
    // crucially updates the rewards data before processing the withdraw operation
    // nonReentrant prevents this function from being called again in the same transaction. This stops malicious and/or untrusted actors or buggy code from manipulating the contract's invariants
    function withdraw(uint256 amount) override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    // allows a user to claim their rewards
    // crucially updates the rewards data before processing the getReward operation
    // nonReentrant prevents this function from being called again in the same transaction. This stops malicious and/or untrusted actors or buggy code from manipulating the contract's invariants
    function getReward() override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];

        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // allows the user to withdraw their staked tokens and claim their rewards in the same transaction
    function exit() override external {
        withdraw(_balances[msg.sender]); // withdraws the sender's balance
        getReward(); // pays the sender their staking reward
    }

    // ========== RESTRICTED FUNCTIONS ========== //

    // Add rewards to the contract for distribution
    function notifyRewardAmount(
        uint256 _reward
    ) override virtual external whenActive onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration); // lifetime doesn't start until rewards are added
        emit RewardAdded(_reward);
    }

    // sets the reward duration
    function setRewardsDuration(uint256 _rewardsDuration) virtual external whenActive onlyOwner {
        require(_rewardsDuration > 0, "empty _rewardsDuration");

        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );

        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    // when farming was started with 1y and 12tokens
    // and we want to finish after 4 months, we need to end up with situation
    // like we were starting with 4mo and 4 tokens.
    // there is usually an agreement that a specific number or percentage of tokens will be allocated for speicifc purposes
    function finishFarming() external whenActive onlyOwner {
        require(block.timestamp < periodFinish, "can't stop if not started or already finished");

        stopped = true;
        uint256 tokensToBurn;

        if (_totalSupply == 0) {
            tokensToBurn = rewardsToken.balanceOf(address(this));
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            tokensToBurn = rewardRate.mul(remaining);
            rewardsDuration = rewardsDuration - remaining;
        }

        periodFinish = block.timestamp;
        // IBurnableToken(address(rewardsToken)).burn(tokensToBurn);
        rewardsToken.burn(tokensToBurn);

        emit FarmingFinished(tokensToBurn);
    }

    // ========== MODIFIERS ========== //

    // modifies a function such that it cannot be called unless it is active
    modifier whenActive() {
        require(!stopped, "farming is stopped");
        _;
    }

    // updates the reward info
    // updates rewardPerTokenStored, which changes based on lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
    // updates lastUpdateTime to the current time or periodFinish
    // updates the user's rewards and the reward the user was last paid on their staked tokens
    modifier updateReward(address account) virtual {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // ========== EVENTS ========== //

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event FarmingFinished(uint256 burnedTokens);
}