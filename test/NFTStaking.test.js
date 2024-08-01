const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTStaking Contract", function () {
  let nftStaking, nftContract, rewardToken, owner, userA;
  let rewardRate = ethers.utils.parseUnits("1", 18); 
  let delayPeriod = 100; 
  let unbondingPeriod = 50; 

  beforeEach(async function () {
    // Deploy mock ERC721 and ERC20 contracts
    const MockERC721 = await ethers.getContractFactory("MockERC721");
    nftContract = await MockERC721.deploy("MockNFT", "MNFT");
    await nftContract.deployed();

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    rewardToken = await MockERC20.deploy("RewardToken", "RWT", 1000000);
    await rewardToken.deployed();

    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    [owner, userA] = await ethers.getSigners();
    nftStaking = await NFTStaking.deploy();
    await nftStaking.initialize(nftContract.address, rewardToken.address, rewardRate, delayPeriod, unbondingPeriod);

    await nftContract.connect(userA).mint(1);
    await nftContract.connect(userA).mint(2);

    await rewardToken.transfer(nftStaking.address, ethers.utils.parseUnits("10000", 18));
  });

  it("Should allow user to stake NFTs", async function () {
    await nftContract.connect(userA).setApprovalForAll(nftStaking.address, true);

    await nftStaking.connect(userA).stakeNFT([1, 2]);

    const stakedNFT1 = await nftStaking.stakedNFTs(1);
    expect(stakedNFT1.owner).to.equal(userA.address);
    const stakedNFT2 = await nftStaking.stakedNFTs(2);
    expect(stakedNFT2.owner).to.equal(userA.address);
  });

  it("Should update reward rate and calculate rewards correctly", async function () {
    await nftContract.connect(userA).setApprovalForAll(nftStaking.address, true);
    await nftStaking.connect(userA).stakeNFT([1]);

    await network.provider.send("evm_mine", [delayPeriod + 10]);

    const newRewardRate = ethers.utils.parseUnits("2", 18); // New reward rate
    await nftStaking.connect(owner).updateRewardRate(newRewardRate);

    const initialBalance = await rewardToken.balanceOf(userA.address);
    await nftStaking.connect(userA).claimRewards();
    const finalBalance = await rewardToken.balanceOf(userA.address);

    expect(finalBalance).to.be.gt(initialBalance);
  });

  it("Should allow user to unstake and withdraw NFTs", async function () {
    await nftContract.connect(userA).setApprovalForAll(nftStaking.address, true);
    await nftStaking.connect(userA).stakeNFT([1]);

    await nftStaking.connect(userA).unstakeNFT([1]);

    await network.provider.send("evm_mine", [unbondingPeriod + 10]);

    await nftStaking.connect(userA).withdrawNFT(1);

    const ownerOfNFT1 = await nftContract.ownerOf(1);
    expect(ownerOfNFT1).to.equal(userA.address);
  });

});
