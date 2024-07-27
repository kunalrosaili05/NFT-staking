// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract NFTStaking is Initializable, UUPSUpgradeable, PausableUpgradeable {
        // Address of the ERC721 contract (NFTs)
    IERC721Upgradeable public nftContract;
    
    // Address of the ERC20 contract (Reward tokens)
    IERC20Upgradeable public rewardToken;
    
// Rate at which rewards are calculated (per block)
    uint256 public rewardRate;
    
    // Number of blocks required before rewards can be claimed
    uint256 public delayPeriod;
    
      // Number of blocks required to unbond a staked NFT
    uint256 public unbondingPeriod;

  // Structure to hold information about a staked NFT
    struct StakedNFT {
        address owner;               // Owner of the staked NFT
        uint256 stakedBlock;         // Block number when the NFT was staked
        uint256 rewardsClaimedBlock; // Block number when rewards were last claimed
        bool unstaked;               // Status indicating if the NFT has been unstaked
        uint256 unstakedBlock;       // Block number when the NFT was unstaked
    }

 // Mapping from NFT ID to its staked information
    mapping(uint256 => StakedNFT) public stakedNFTs;
    
       // Mapping from owner address to the list of staked NFT IDs
    mapping(address => uint256[]) public ownerToNFTs;

    // Events to log important actions
    event NFTStaked(address indexed owner, uint256 indexed nftId);
    event NFTUnstaked(address indexed owner, uint256 indexed nftId);
    event RewardsClaimed(address indexed owner, uint256 reward);

       // Modifier to ensure the caller is the owner of the NFT
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
        __Pausable_init();
        __UUPSUpgradeable_init();
        nftContract = IERC721Upgradeable(_nftContract);
        rewardToken = IERC20Upgradeable(_rewardToken);
        rewardRate = _rewardRate;
        delayPeriod = _delayPeriod;
        unbondingPeriod = _unbondingPeriod;
    }


    function stakeNFT(uint256[] calldata nftIds) external whenNotPaused {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            require(nftContract.ownerOf(nftId) == msg.sender, "You must own the NFT");
            
            // Transfer the NFT to the contract
            nftContract.transferFrom(msg.sender, address(this), nftId);

            // Record the staked NFT details
            stakedNFTs[nftId] = StakedNFT({
                owner: msg.sender,
                stakedBlock: block.number,
                rewardsClaimedBlock: block.number,
                unstaked: false,
                unstakedBlock: 0
            });

            // Track the staked NFT for the owner
            ownerToNFTs[msg.sender].push(nftId);

            emit NFTStaked(msg.sender, nftId);
        }
    }

    function unstakeNFT(uint256[] calldata nftIds) external {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            require(stakedNFTs[nftId].owner == msg.sender, "Not the NFT owner");
            require(!stakedNFTs[nftId].unstaked, "Already unstaked");

            // Mark the NFT as unstaked
            stakedNFTs[nftId].unstaked = true;
            stakedNFTs[nftId].unstakedBlock = block.number;

            emit NFTUnstaked(msg.sender, nftId);
        }
    }

    function withdrawNFT(uint256 nftId) external onlyNFTOwner(nftId) {
        require(stakedNFTs[nftId].unstaked, "NFT not unstaked");
        require(block.number >= stakedNFTs[nftId].unstakedBlock + unbondingPeriod, "Unbonding period not passed");

        // Transfer the NFT back to the owner
        nftContract.transferFrom(address(this), msg.sender, nftId);

        // Remove the NFT from the staked mapping
        delete stakedNFTs[nftId];
    }


    function claimRewards() external whenNotPaused {
        uint256 totalRewards = 0;
        uint256[] storage nftIds = ownerToNFTs[msg.sender];

        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];

            if (stakedNFTs[nftId].owner == msg.sender && !stakedNFTs[nftId].unstaked) {
                StakedNFT storage stakedNFT = stakedNFTs[nftId];

                // Check if the delay period has passed since the last reward claim
                if (block.number >= stakedNFT.rewardsClaimedBlock + delayPeriod) {
                    uint256 rewardBlocks = block.number - stakedNFT.rewardsClaimedBlock;
                    totalRewards += rewardBlocks * rewardRate;

                    // Update the last claimed block
                    stakedNFT.rewardsClaimedBlock = block.number;
                }
            }
        }

        require(totalRewards > 0, "No rewards to claim");

        // Transfer the calculated rewards to the owner
        rewardToken.transfer(msg.sender, totalRewards);

        emit RewardsClaimed(msg.sender, totalRewards);
    }

    
    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }

    
    function updateRewardRate(uint256 newRewardRate) external {
        rewardRate = newRewardRate;
    }

    
    function updateStakingConfig(uint256 newDelayPeriod, uint256 newUnbondingPeriod) external {
        delayPeriod = newDelayPeriod;
        unbondingPeriod = newUnbondingPeriod;
    }
}
