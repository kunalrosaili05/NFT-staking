async function main() {
    const [deployer] = await ethers.getSigners();
    
    console.log("Deploying contracts with the account:", deployer.address);
  
    const NFTStaking = await ethers.getContractFactory("NFTStaking");
    const nftStaking = await NFTStaking.deploy(
      "0x14fc82a97742e034d0a5b3841c7997f7aa1c0307",     //ERC721 address
      "0x345cb9daaeaad758784624723224ac21c7f73261", //ERC20 address
      1e18, 
      1000, 
      10000  
    );
  
    await nftStaking.deployed();
  
    console.log("NFTStaking contract deployed to:", nftStaking.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  