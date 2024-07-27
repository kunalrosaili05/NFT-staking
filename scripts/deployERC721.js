const { ethers } = require("hardhat");

async function main() {
  const MockNFT = await ethers.getContractFactory("MockNFT");
  console.log("Deploying MockNFT...");

  const mockNFT = await MockNFT.deploy();
  await mockNFT.deployed();
  console.log("MockNFT deployed to:", mockNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
