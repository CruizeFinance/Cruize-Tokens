import { expect } from "chai";
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";
import hre, { ethers } from "hardhat";
import { BigNumber, constants, Contract } from "ethers";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

function bg(number: string) {
  return BigNumber.from(number);
}

export async function increaseTime(duration: number): Promise<void> {
  ethers.provider.send("evm_increaseTime", [duration]);
  ethers.provider.send("evm_mine", []);
}

export const Impersonate = async(address:string):Promise<SignerWithAddress> =>{
  await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [address],
    });
    const account = await ethers.getSigner(address)
    return account;
}

describe("CruizeToken Vesting", function () {
  let vesting: Contract;
  let cruizeToken: Contract;
  let armadaToken: Contract;
  let signer: SignerWithAddress;
  let cruizeWallet: SignerWithAddress;

  before(async () => {
    [signer, cruizeWallet] = await ethers.getSigners();

    hre.tracer.nameTags[signer.address] = "Singer";
    hre.tracer.nameTags[cruizeWallet.address] = "Cruize-Wallet";
    
    const CruizeToken = await ethers.getContractFactory("CruizeToken", signer);
    cruizeToken = await CruizeToken.deploy(signer.address);

    const ArmadaToken = await ethers.getContractFactory("ArmadaToken", signer);
    armadaToken = await ArmadaToken.deploy();
    await armadaToken.initialize();

    const TokenVesting = await ethers.getContractFactory(
      "TokenVesting",
      signer
    );
    vesting = await TokenVesting.deploy();
    await vesting.initialize(cruizeToken.address, armadaToken.address);

    hre.tracer.nameTags[vesting.address] = "Vesting";
    hre.tracer.nameTags[cruizeToken.address] = "Cruize-Token";
    hre.tracer.nameTags[armadaToken.address] = "Armada-Token";

    await armadaToken.setVestingAddress(vesting.address);
  });

  it.only("test mainnet token",async () => {
    let cruizeOwner = await Impersonate("0xcDC1C7C9A1c4F93a1043bcDC3eA004D3D72d6b06")
    let crToken  = await ethers.getContractAt("CruizeToken","0x232bAF8CFc14520140c3686FbAb53Fa596a50552");
    await crToken.connect(cruizeOwner).callStatic.burn(parseEther("100"));
  })

  it.only("Convert Cruize-Armada tokens", async function () {
    await cruizeToken.approve(vesting.address, constants.MaxUint256);
    await vesting.convert(parseEther("100"));
  });

  it.only("Throw, if transfer armada by normal user", async function () {
    await armadaToken.transfer(cruizeWallet.address, parseEther("100"));
    await expect(armadaToken.connect(cruizeWallet).transfer(signer.address, parseEther("100"))).to.be.revertedWith("NOT-TRANSFERRABLE");
    await armadaToken.burn(cruizeWallet.address, parseEther("100"));
  
  });

  it.only("Convert Cruize-Armada tokens", async function () {
    await cruizeToken.approve(vesting.address, constants.MaxUint256);
    await vesting.convert(parseEther("100"));
  });

  it.only("Mint armada Tokens by owner", async function () {
    await armadaToken.mint(signer.address, parseEther("1000"));
  });

  it.only("Transfer Armada tokens and burn", async function () {
    await armadaToken.transfer(cruizeWallet.address, parseEther("1000"));
    await armadaToken.burn(cruizeWallet.address, parseEther("1000"));
  });


  it.only("Claim Cruize tokens", async function () {
    await vesting.claim(parseEther("100"));
  });

  it.only("Throw,if user does not have armada tokens", async function () {
    await expect(vesting.connect(cruizeWallet).claim(parseEther("100"))).to.be
      .reverted;
  });

  it.only("Throw, if Release Cruize tokens before time", async function () {
    await increaseTime(86400 * 50);
    await expect(
      vesting.release(0)
    ).to.be.revertedWithCustomError(vesting, "NOT_RELEASEABLE");
  });

  it.only("Release Cruize tokens after 10 days of epoche", async function () {
    await increaseTime(86400 * 23);
    await vesting.release(0);
  });

  it.only("Convert Cruize-Armada tokens", async function () {
    await cruizeToken.approve(vesting.address, constants.MaxUint256);
    await vesting.convert(parseEther("100"));
  });

  it.only("Claim Cruize tokens After 10 days of epoche", async function () {
    await vesting.claim(parseEther("100"));
  });

  it("Throw, if try to Release all Cruize tokens before vesting end period", async function () {
    await increaseTime(86400*80)
    await expect(
      vesting.release(0, parseEther("90"))
    ).to.be.revertedWithCustomError(vesting, "NOT_ENOUGH_RELEASEABLE_AMOUNT");
    await vesting.release(0, constants.MaxUint256);
    await expect(vesting.release(0, constants.MaxUint256)).to.be.revertedWithCustomError(vesting,"ALREADY_RELEASED")
  });

  it("Convert Cruize-Armada tokens", async function () {
    await cruizeToken.approve(vesting.address, constants.MaxUint256);
    await vesting.convert(parseEther("100"));
  });

  it("Claim Cruize tokens", async function () {
    await vesting.claim(parseEther("100"));
  });
  

  
});
