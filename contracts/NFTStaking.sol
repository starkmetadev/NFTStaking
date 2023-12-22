/**
 *Submitted for verification at snowtrace.io on 2022-08-11
*/

// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

library SafeMath {

 function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC165 {
     function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    struct NFTInfo {
        address user;
        uint256 amount;
        uint8 tie;
        uint256 tokenId;
    }
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract NFTStaking is Ownable {
    using SafeMath for uint256;

    IERC20 public  rewardToken;
    IERC721Metadata public StakeNFT;
    uint256 distributionPeriod = 10;

    uint256 rewardPoolBalance;

    // default divisor is 6
    uint8 public divisor = 10;

    uint256 public rewardClaimInterval = 4 hours; // user can claim reward every 12 hours

    uint256 public totalStaked;     // current total staked value
    uint256 public circulationAmount;

    address deadAddress = 0x000000000000000000000000000000000000dEaD;
    address rewardWallet;

    uint256 minInterval = 15 minutes; // rewards is accumulated every 4 hours

    struct StakeInfo {
        int128 duration;  // -1: irreversible, others: reversible (0, 30, 90, 180, 365 days which means lock periods)
        uint256 amount; // staked amount
        uint256 stakedTime; // initial staked time
        uint256 lastClaimed; // last claimed block
        uint256 lastblock; // last claimed time
        uint256 blockListIndex; // blockList id which is used in calculating rewards
        bool available;     // if diposit, true: if withdraw, false
        string name;    // unique id of the stake
        uint256 NFTStakingId;
    }

    // this will be updated whenever new stake or lock processes
    struct BlockInfo {
        uint256 blockNumber;      
        uint256 totalStaked;      // this is used for calculating reward.
    }

    mapping(bytes32 => StakeInfo) stakedUserList;
    mapping (address => bytes32[]) userInfoList; // container of user's id
    BlockInfo[] public blockList;

    uint256 defaultAmountForNFT;

    uint256 initialTime;        // it has the block time when first deposit in this contract (used for calculating rewards)

    mapping(address => bool) public whiteList;
    mapping(address => bool) public blackList;

    bool public useWhiteList;
    uint8 unLockBoost = 10;
    uint8 month1 = 15;
    uint8 month3 = 18;
    uint8 month6 = 20;
    uint8 year1 = 25;

    event Deposit(address indexed user, string name, uint256 amount);
    event DepositNFT(address indexed user, string name, uint256 tokenId);
    event Withdraw(address indexed user, string name, uint256 amount);
    event NewDeposit(address indexed user, string name, uint256 amount);
    event SendToken(address indexed token, address indexed sender, uint256 amount);
    event SendTokenMulti(address indexed token, uint256 amount);
    event ClaimReward(address rewardToken, address indexed user, uint256 amount);
    event Received(address, uint);

    constructor (address _rewardToken, address _nftAddr){
        // this is for main net
        StakeNFT = IERC721Metadata(_nftAddr);
        rewardToken = IERC20(_rewardToken);
        whiteList[_msgSender()] = true;

        rewardPoolBalance = 100_000_000 * 10 ** IERC20Metadata(_rewardToken).decimals();
        defaultAmountForNFT = 100_000_000 * 10 ** 18;
        // initialTime = 1661213742;
    }
    
    function _string2byte32(string memory name) private view returns(bytes32) {
        return keccak256(abi.encodePacked(name, _msgSender()));
    }

    // check if the given name is unique id
    function isExistStakeId(string memory name) public view returns (bool) {
        return stakedUserList[_string2byte32(name)].available;
    }

    // change Reward Poll Pool Balance but in case of only owner
    function setRewardPoolBalance(uint256 _balance) external onlyOwner {
        rewardPoolBalance = _balance;
    }

    function setStakeNFT(address nftAddr) external onlyOwner {
        StakeNFT = IERC721Metadata(nftAddr);
    }

    function setRewardToken(address _rewardToken)  external onlyOwner {
        rewardToken = IERC20(_rewardToken);
    }

    function setDistributionPeriod(uint256 _period) external onlyOwner {
        distributionPeriod = _period;
    }

    function setDivisor (uint8 _divisor) external onlyOwner {
        divisor = _divisor;
    }

    function setMinInterval (uint256 interval) external onlyOwner {
        minInterval = interval;
    }

    function setRewardInterval (uint256 _interval) external onlyOwner {
        rewardClaimInterval = _interval;
    }

    function setRewardWallet(address wallet) external onlyOwner {
        rewardWallet = wallet;
    }

    function setDefaultAmountForNFT(uint amount) external onlyOwner {
            defaultAmountForNFT = amount;
    }

    function doable (address user) private view returns(bool) {
        if(blackList[user]) return false;
        if(!useWhiteList) return true;
        if(useWhiteList && whiteList[user]) return true;
        return false;
    }

    function updateWhiteList (address[] memory users, bool flag) external onlyOwner {
        for(uint256 i = 0; i < users.length; i++) {
            whiteList[users[i]] = flag;
        }
    }

    function updateBlackList (address[] memory users, bool flag) external onlyOwner {
        for(uint256 i = 0; i < users.length; i++) {
            blackList[users[i]] = flag;
        }
    }

    function setUseWhiteList(bool flag) external onlyOwner {
        useWhiteList = flag;
    }

    function setBoostConst(uint8 _type, uint8 val) external onlyOwner {
        if(_type == 0) unLockBoost = val;
        else if(_type == 1) month1 = val;
        else if(_type == 2) month3 = val;
        else if(_type == 3) month6 = val;
        else if(_type == 4) year1 = val;
    }

    // send tokens out inside this contract into any address. 
    // when the specified token is stake token, the minmum value should be equal or bigger than thresholdMinimum amount.
    function recoverToken (address token, address sender, uint256 amount) external onlyOwner {
        if (IERC20(token).balanceOf(address(this)) < amount) amount = IERC20(token).balanceOf(address(this));
        IERC20Metadata(token).transfer(sender, amount);
    }

    // update the blockList table
    // when deposit, totalStaked increases; when withdraw, totalStaked decreases (if isPush is true this is deposit mode, or else withdraw)
    function _updateBlockList(uint256 amount, bool isPush, int128 duration) private {
        uint256 len = blockList.length;
        if(isPush) {
            if(duration >= 0) {
                circulationAmount = circulationAmount.add(amount);
            }
            totalStaked = totalStaked.add(amount);
        } else {
            totalStaked = totalStaked.sub(amount);
            if(duration >= 0) {
                circulationAmount = circulationAmount.sub(amount);
            }
        }

        uint256 time = block.timestamp;

        time = time - (time - initialTime) % minInterval;

        if(len == 0) {
            blockList.push(BlockInfo({
                blockNumber : time,
                totalStaked : totalStaked
            }));
        } else {
            // when the reward is not accumulated yet
            if((time - blockList[len-1].blockNumber) / minInterval == 0) { 
                blockList[len-1].totalStaked = totalStaked;
            } else {
                blockList.push(BlockInfo({
                    blockNumber : time,
                    totalStaked : totalStaked
                }));
            }
        }
    }

    // when staked, new StakeInfo is added: when withdraw this stakeInfo is no available anymore (avaliable = false)
    function _updateStakedList(string memory name, int128 duration, uint256 amount, bool available) private {
        bytes32 key = _string2byte32(name); 
        StakeInfo storage info = stakedUserList[key];
        info.available = available;
        if(!available) {
            info.amount = 0;
            return; // when withdraw mode
        }

        uint256 time = block.timestamp;
        time = time - (time - initialTime) % minInterval;

        info.amount = info.amount.add(amount);
        info.blockListIndex = blockList.length - 1;
        info.stakedTime = block.timestamp;
        info.lastClaimed = block.timestamp;
        info.lastblock = time;
        info.duration = duration;
        info.name = name;
    }

    // update the user list table
    function _updateUserList(string memory name, bool isPush) private {
        bytes32 key = _string2byte32(name);
        if(isPush)
            userInfoList[_msgSender()].push(key);
        else {
            // remove user id from the userList
            for (uint256 i = 0; i < userInfoList[_msgSender()].length; i++) {
                if (userInfoList[_msgSender()][i] == key) {
                    userInfoList[_msgSender()][i] = userInfoList[_msgSender()][userInfoList[_msgSender()].length - 1];
                    userInfoList[_msgSender()].pop();
                    break;
                }
            }
        }
    }

    function stakeNFT(string memory name, uint256 tokenId) external {
        require(doable(_msgSender()), "NA");
        require(!isExistStakeId(name), "id existed!");

        if(initialTime == 0) {
            initialTime = block.timestamp;
        }

        uint amount = defaultAmountForNFT;
        _updateBlockList(amount, true, 0);
        _updateStakedList(name, 0, amount, true);
        _updateUserList(name, true);
        bytes32 key = _string2byte32(name);
        StakeInfo storage info = stakedUserList[key];
        info.NFTStakingId = tokenId;
        StakeNFT.transferFrom(_msgSender(), address(this), tokenId);
        emit DepositNFT(_msgSender(), name, tokenId);
    }

    function unStakeNFT(string memory name) external {
        require(doable(_msgSender()), "NA");
        require(isExistStakeId(name), "doesn't existed!");
        uint256 amount = stakedUserList[_string2byte32(name)].amount;
        require(stakedUserList[_string2byte32(name)].NFTStakingId != 0, "Invalid operatorN");
        // (uint a, ) = unClaimedReward(name);
        // if(a > 0) _claimReward(name, true);
        _updateBlockList(amount, false, 0);
        _updateStakedList(name, 0, 0, false);
        _updateUserList(name, false);

        StakeNFT.transferFrom(address(this), _msgSender(), stakedUserList[_string2byte32(name)].NFTStakingId);
    }
    
    function getBoost(int128 duration, uint256 amount) private view returns (uint8) {
        // if(duration < 0 && amount < 100 * 10 ** 6 * 10 ** 18) return 0;
        if (duration < 30) return unLockBoost;   // no lock
        else if (duration < 90) return month1;   // more than 1 month
        else if (duration < 180) return month3;   // more than 3 month
        else if (duration < 360) return month6;  // more than 6 month
        else return year1;                      // more than 12 month
    }

    function isWithdrawable(string memory name) public view returns(bool) {
        StakeInfo storage stakeInfo = stakedUserList[_string2byte32(name)];
        // when Irreversible mode
        if (stakeInfo.duration < 0) return true;
        if (uint256(uint128(stakeInfo.duration) * 1 days) <= block.timestamp - stakeInfo.stakedTime) return true;
        else return false;
    }

    function _calculateReward(string memory name) private view returns(uint256) {
        require(isExistStakeId(name), "not exist");
        require(totalStaked != 0, "no staked");
        StakeInfo storage stakeInfo = stakedUserList[_string2byte32(name)];

        uint256 lastblock = stakeInfo.lastblock;
        uint256 blockIndex = stakeInfo.blockListIndex;
        uint256 stakedAmount = stakeInfo.amount;
        uint256 reward = 0;
        uint256 boost = getBoost(stakeInfo.duration, stakedAmount);

        for (uint256 i = blockIndex + 1; i < blockList.length; i++) {
            uint256 _totalStaked = blockList[i].totalStaked;
            if(_totalStaked == 0) continue;
            reward = reward + ((blockList[i].blockNumber - lastblock).div(minInterval) 
                                * (rewardPoolBalance * stakedAmount * boost / distributionPeriod  / _totalStaked / divisor / 10 )  // formula // 10 => boost divisor
                                * (minInterval)  / (24 hours));
            lastblock = blockList[i].blockNumber;
            
        }

        reward = reward + ((block.timestamp - lastblock).div(minInterval) 
                                * (rewardPoolBalance * stakedAmount * boost / distributionPeriod  / totalStaked / divisor / 10)  // formula
                                * (minInterval)  / (24 hours));
        return reward;
    }

    function unClaimedReward(string memory name) public view returns(uint256, bool) {
        if(!isExistStakeId(name)) return (0, false);
        uint256 reward = _calculateReward(name);
        return (reward, true);
    }

    function unclaimedAllRewards(address user, int128 period, bool all) external view returns(uint256 resVal) {
        bool exist;
        for (uint256 i = 0; i < userInfoList[user].length; i++) {
            if(!all && getBoost(stakedUserList[userInfoList[user][i]].duration, stakedUserList[userInfoList[user][i]].amount) != getBoost(period, stakedUserList[userInfoList[user][i]].amount)) continue;
            uint256 claimedReward;
            (claimedReward, exist) = unClaimedReward(stakedUserList[userInfoList[user][i]].name);
            if(!exist) continue;
            resVal += claimedReward;
        }
        return (resVal);
    }

    function claimReward(string memory name) public {
        require(isExistStakeId(name), "not exist");
        require(doable(_msgSender()), "NA");
        require(isClaimable(name), "period not expired!");
        uint256 reward = _calculateReward(name);
        // require(rewardToken.balanceOf(address(this)) >= circulationAmount + reward, "Insufficent pool balance");
        bytes32 key = _string2byte32(name);
        // update blockListIndex and lastClaimed value
        StakeInfo storage info = stakedUserList[key];
        info.blockListIndex = blockList.length - 1;
        uint256 time = block.timestamp;
        info.lastblock = time - (time - initialTime) % minInterval;
        info.lastClaimed = block.timestamp;
        if (rewardToken.balanceOf(address(this)) < reward) reward = rewardToken.balanceOf(address(this));
        rewardToken.transfer(_msgSender(), reward);

        emit ClaimReward(address(rewardToken), _msgSender(), reward);
    }

    function isClaimable(string memory name) public view returns(bool) {
        require(isExistStakeId(name), "not exist");
        StakeInfo storage stakeInfo = stakedUserList[_string2byte32(name)];
        uint256 lastblock = stakeInfo.lastblock;
        
        if((block.timestamp - lastblock) / (rewardClaimInterval) > 0) return true;
        else return false;
    }

    function getUserStakedInfo(address user) external view returns (uint256 length, StakeInfo[] memory info, uint256[] memory dailyReward) {
        length = userInfoList[user].length;
        dailyReward = new uint256[](length);
        info = new StakeInfo[](length);
        for (uint256 i = 0; i < userInfoList[user].length; i++) {
            info[i] = stakedUserList[userInfoList[user][i]];
            uint256 boost = getBoost(info[i].duration, info[i].amount);
            dailyReward[i] = (rewardPoolBalance * info[i].amount * boost / 10 / distributionPeriod  / totalStaked / divisor ); // 10 => boost divisor
        }

        return (length, info, dailyReward);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // 
    function getUserStakedNFT(string memory name) external view returns(uint256 tokenId, string memory uri) {
        if (!isExistStakeId(name)) return (0, "");
        return (stakedUserList[_string2byte32(name)].NFTStakingId, StakeNFT.tokenURI(stakedUserList[_string2byte32(name)].NFTStakingId));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}