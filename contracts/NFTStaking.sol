// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTStaking is Initializable, UUPSUpgradeable, PausableUpgradeable, OwnableUpgradeable {
 // With this, we set up the contract to work with the ERC721 NFT contract
    IERC721Upgradeable public nftContract;
    
    // With this, we specify the ERC20 token contract that will be used for rewards
    IERC20Upgradeable public rewardToken;
    
        // With this, we define the rate at which rewards are calculated (per block)
    uint256 public rewardRate;
    
  // With this, we set the number of blocks required before rewards can be claimed
    uint256 public delayPeriod;
    
    // With this, we determine the number of blocks required to unbond a staked NFT
    uint256 public unbondingPeriod;

      // With this structure, we hold information about each staked NFT
    struct StakedNFT {
        address owner;               // Owner of the staked NFT
        uint256 stakedBlock;         // Block number when the NFT was staked
        uint256 rewardsClaimedBlock; // Block number when rewards were last claimed
        bool unstaked;               // Status indicating if the NFT has been unstaked
        uint256 unstakedBlock;       // Block number when the NFT was unstaked
    }

 // With this, we map each NFT ID to its staked information
    mapping(uint256 => StakedNFT) public stakedNFTs;
    
    // With this, we map each owner address to their list of staked NFT IDs
    mapping(address => uint256[]) public ownerToNFTs;

    // With these events, we log important actions for transparency
    event NFTStaked(address indexed owner, uint256 indexed nftId);
    event NFTUnstaked(address indexed owner, uint256 indexed nftId);
    event RewardsClaimed(address indexed owner, uint256 reward);

      // With this modifier, we ensure that only the owner of an NFT can access certain functions
    modifier onlyNFTOwner(uint256 nftId) {
        require(stakedNFTs[nftId].owner == msg.sender, "Not the NFT owner");
        _;
    }

    function initialize(
        address _nftContract,
        address _rewardToken,
        uint256 _rewardRate,
        uint256 _delayPeriod,
        uint256 _unbondingPeriod
    ) public initializer {
        __Ownable_init(msg.sender);      // With this, we set the initial owner of the contract
        __Pausable_init();
        __UUPSUpgradeable_init();

        nftContract = IERC721Upgradeable(_nftContract);
        rewardToken = IERC20Upgradeable(_rewardToken);
        rewardRate = _rewardRate;
        delayPeriod = _delayPeriod;
        unbondingPeriod = _unbondingPeriod;
    }

    // With this constructor, we disable initializers to prevent the contract from being initialized again
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function stakeNFT(uint256[] calldata nftIds) external whenNotPaused {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            require(nftContract.ownerOf(nftId) == msg.sender, "You must own the NFT");
            
        // With this, we transfer the NFT to the contract
            nftContract.transferFrom(msg.sender, address(this), nftId);

            // With this, we record the details of the staked NFT
            stakedNFTs[nftId] = StakedNFT({
                owner: msg.sender,
                stakedBlock: block.number,
                rewardsClaimedBlock: block.number,
                unstaked: false,
                unstakedBlock: 0
            });

                 // With this, we keep track of the staked NFT for the owner
            ownerToNFTs[msg.sender].push(nftId);

            emit NFTStaked(msg.sender, nftId);
        }
    }

    function unstakeNFT(uint256[] calldata nftIds) external {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            require(stakedNFTs[nftId].owner == msg.sender, "Not the NFT owner");
            require(!stakedNFTs[nftId].unstaked, "Already unstaked");

               // With this, we mark the NFT as unstaked
            stakedNFTs[nftId].unstaked = true;
            stakedNFTs[nftId].unstakedBlock = block.number;

            emit NFTUnstaked(msg.sender, nftId);
        }
    }

    function withdrawNFT(uint256 nftId) external onlyNFTOwner(nftId) {
        require(stakedNFTs[nftId].unstaked, "NFT not unstaked");
        require(block.number >= stakedNFTs[nftId].unstakedBlock + unbondingPeriod, "Unbonding period not passed");

 // With this, we remove the NFT from the staked mapping before transferring it back
        delete stakedNFTs[nftId];

        // With this, we transfer the NFT back to the owner
        nftContract.transferFrom(address(this), msg.sender, nftId);
    }

    function claimRewards() external whenNotPaused {
        uint256 totalRewards = 0;
        uint256[] storage nftIds = ownerToNFTs[msg.sender];

        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];

            if (stakedNFTs[nftId].owner == msg.sender && !stakedNFTs[nftId].unstaked) {
                StakedNFT storage stakedNFT = stakedNFTs[nftId];

             // With this, we check if the delay period has passed since the last reward claim
                if (block.number >= stakedNFT.rewardsClaimedBlock + delayPeriod) {
                    uint256 rewardBlocks = block.number - stakedNFT.rewardsClaimedBlock;
                    totalRewards += rewardBlocks * rewardRate;

                    // With this, we update the last claimed block
                    stakedNFT.rewardsClaimedBlock = block.number;
                }
            }
        }

        require(totalRewards > 0, "No rewards to claim");
        require(rewardToken.balanceOf(address(this)) >= totalRewards, "Insufficient rewards available");

        // With this, we transfer the calculated rewards to the owner
        rewardToken.transfer(msg.sender, totalRewards);

        emit RewardsClaimed(msg.sender, totalRewards);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateRewardRate(uint256 newRewardRate) external onlyOwner {
        rewardRate = newRewardRate;
    }

    function updateStakingConfig(uint256 newDelayPeriod, uint256 newUnbondingPeriod) external onlyOwner {
        delayPeriod = newDelayPeriod;
        unbondingPeriod = newUnbondingPeriod;
    }

    function _removeNFTFromOwner(address owner, uint256 nftId) internal {
        uint256[] storage nftIds = ownerToNFTs[owner];
        for (uint256 i = 0; i < nftIds.length; i++) {
            if (nftIds[i] == nftId) {
                nftIds[i] = nftIds[nftIds.length - 1];
                nftIds.pop();
                return;
            }
        }
    }
}
