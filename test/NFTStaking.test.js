const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTStaking", function () {
  let NFTStaking;
  let nftStaking;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const rewardToken = await MockERC20.deploy("Reward Token", "REWARD");
    await rewardToken.deployed();

    const MockNFT = await ethers.getContractFactory("MockNFT");
    const nftContract = await MockNFT.deploy();
    await nftContract.deployed();

    NFTStaking = await ethers.getContractFactory("NFTStaking");
    nftStaking = await NFTStaking.deploy(
      nftContract.address,
      rewardToken.address,
      1e18,
      1000,
      10000
    );
    await nftStaking.deployed();
  });

  it("Should deploy the NFTStaking contract", async function () {
    expect(await nftStaking.address).to.not.be.undefined;
  });

});
