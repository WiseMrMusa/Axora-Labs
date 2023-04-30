// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../test/MasterChefTest/TestToken.sol";



// MasterChef is the master of Cake. He can make Cake and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CAKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 lastInteracted; // Last time user deposited or withdrew
        uint256 rewardAccrued; // Share indicating the user's share of pool reward
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAxoraReward) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accAxoraReward` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that CAKEs distribution occurs.
        uint256 accAxoraReward; // Accumulated CAKEs per share, times 1e12. See below.
        uint256 totalDepositors; // Total number of people that have deposited
    }

    // The Axora TOKEN!
    TokenContract public axora;
    // Dev address.
    address public devaddr;
    // AXORA tokens created per block.
    uint256 public axoraPerBlock;
    // Bonus muliplier for early cake makers.
    uint256 public BONUS_MULTIPLIER = 1;


    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        TokenContract _axora,
        address _devaddr,
        uint256 _axoraPerBlock,
        uint256 _startBlock
    ) {
        axora = _axora;
        devaddr = _devaddr;
        axoraPerBlock = _axoraPerBlock;
        startBlock = _startBlock;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.timestamp > startBlock ? block.timestamp : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accAxoraReward : 0,
            totalDepositors : 0
        }));
        updateTotalAllocPoint();
    }

    // Update the given pool's CAKE allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateTotalAllocPoint();
        }
    }

    function updateTotalAllocPoint() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            totalAllocPoint = points;
        }
    }



    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }


    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }



    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.timestamp);
        uint256 poolAxoraReward = multiplier.mul(axoraPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        axora.mint(poolAxoraReward);
        pool.accAxoraReward = poolAxoraReward;
        pool.lastRewardBlock = block.timestamp;
    }




    // View function to see pending AXORAs on frontend.
    function pendingAxora(uint256 _pid, address _user) public returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 _rewardAccrued = user.rewardAccrued;
        uint256 _userMultiplier = getMultiplier(user.lastInteracted, block.timestamp);
        uint256 totalAccRewardInUserTimeRange = _userMultiplier.mul(axoraPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardBlock && lpSupply != 0) {
            uint256 _reward = user.amount.mul(totalAccRewardInUserTimeRange).div(lpSupply);
            user.rewardAccrued = _rewardAccrued.add(_reward);
        }
        user.lastInteracted = block.timestamp;
        return user.rewardAccrued;
    }


    // Deposit LP tokens to MasterChef for AXORA allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        uint length = poolInfo.length;
        require(_pid < length, "Pool does not exist");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount == 0) {
            pool.totalDepositors++;
        }

        updatePool(_pid);
        uint256 pending = pendingAxora(_pid, msg.sender);

        if (user.amount > 0) {
            if (pending > 0) {
                axora.transfer(msg.sender, pending);
                user.rewardAccrued = 0;
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.lastInteracted = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
    }



    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        uint length = poolInfo.length;
        require(_pid < length, "Pool does not exist");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint256 pending = pendingAxora(_pid, msg.sender);

        if (pending > 0) {
            axora.transfer(msg.sender, pending);
            user.rewardAccrued = 0;
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.lastInteracted = block.timestamp;
        emit Withdraw(msg.sender, _pid, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardAccrued = 0;
        user.lastInteracted = block.timestamp;
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
