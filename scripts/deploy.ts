import { ethers, upgrades } from "hardhat";

async function main() {
  const ContractFactory = await ethers.getContractFactory("CruizeToken");

  const instance = await upgrades.deployProxy(ContractFactory,[],{
    kind:"transparent"
  });
  await instance.deployed();

  console.log(`Proxy deployed to ${instance.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
