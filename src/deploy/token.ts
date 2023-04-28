import { Address, DeployFunction, Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { contractNames } from "../ts/deploy";

const deployContract: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments } = hre;
  const { deploy, get } = deployments;
  const { ArmadaProxy, CruizeToken,ArmadaToken } =
    contractNames;
  let crToken: Deployment;
  let armadaToken: Deployment;
  let armadaProxy: Deployment;

  let cruizeSafe = "0xcDC1C7C9A1c4F93a1043bcDC3eA004D3D72d6b06"

  let [deployer] = await hre.ethers.getSigners();

  // await deploy(CruizeToken, {
  //   from: deployer.address,
  //   args: [cruizeSafe],
  //   log: true,
  //   deterministicDeployment: false,
  // });
  // crToken = await get(CruizeToken);


  await deploy(ArmadaToken, {
    from: deployer.address,
    args: [],
    log: true,
    deterministicDeployment: false,
  });
  armadaToken = await get(ArmadaToken);
  
  await deploy(ArmadaProxy, {
    from: deployer.address,
    args: [armadaToken.address, deployer.address, "0x"],
    log: true,
    deterministicDeployment: false,
  });
  
  armadaProxy = await get(ArmadaProxy);

  console.table({
    // cruizeToken: crToken.address,
    armadaToken: armadaToken.address,
    armadaProxy: armadaProxy.address,
  });

  // await verify(hre,crToken.address,[cruizeSafe])

  await verify(hre,armadaToken.address,[])
  await verify(hre,armadaProxy.address,[armadaToken.address, deployer.address, "0x"])
};

const verify = async (
  hre: HardhatRuntimeEnvironment,
  contractAddress: Address,
  constructorArgsParams: unknown[]
) => {
  try {
    await hre.run("verify", {
      address: contractAddress,
      constructorArgsParams: constructorArgsParams,
      contract: "contracts/CruizeTokenProxy.sol:CruizeTokenProxy"
    });
  } catch (error) {
    console.log(error);
    console.log(
      `Smart contract at address ${contractAddress} is already verified`
    );
  }
};

export default deployContract;