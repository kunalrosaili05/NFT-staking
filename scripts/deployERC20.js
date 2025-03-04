const { ethers } = require("hardhat");

async function main() {
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  console.log("Deploying MockERC20...");

  const mockERC20 = await MockERC20.deploy();
  await mockERC20.deployed();
  console.log("MockERC20 deployed to:", mockERC20.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
