import { expect } from "chai";
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";
import hre, { ethers } from "hardhat";
import { BigNumber, constants, Contract } from "ethers";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


function bg(number:string) {
  return BigNumber.from(number);
}

export async function increaseTime(duration: number): Promise<void> {
  ethers.provider.send("evm_increaseTime", [duration]);
  ethers.provider.send("evm_mine", []);
}

describe("CruizeToken Vesting", function () {

  let armadaToken:Contract;
  let admin:SignerWithAddress;
  let signer:SignerWithAddress;
  let cruizeWallet:SignerWithAddress;
  
  before(async () =>{
    [admin, signer, cruizeWallet] = await ethers.getSigners();

    const ArmadaToken = await ethers.getContractFactory("ArmadaToken",admin);
    armadaToken = await ArmadaToken.deploy();
    await armadaToken.initialize();

    hre.tracer.nameTags[signer.address] = "Owner";
    hre.tracer.nameTags[admin.address] = "Admin";
    hre.tracer.nameTags[armadaToken.address] = "Armada-Token";
    hre.tracer.nameTags[cruizeWallet.address] = "Cruize-Wallet";
  })

  it("only admin can mint", async function () {
    await armadaToken.connect(admin).mint(admin.address,parseEther("1000"))
    await armadaToken.transfer(cruizeWallet.address,parseEther("500"))
    await armadaToken.transfer(signer.address,parseEther("100"))
  });

  it("Throw, if non-admin try to mint", async function () {
    await expect(armadaToken.connect(signer).mint(admin.address,parseEther("1000"))).to.be.reverted;
  });

  it("only admin can burn", async function () {
    await armadaToken.connect(admin).burn(admin.address,parseEther("100"));
  });

  it("Throw, if non-admin try to burn", async function () {
    await expect(armadaToken.connect(signer).burn(admin.address,parseEther("10"))).to.be.reverted;
  });

  it("Throw,if non-whitelisted user try to transfer", async function () {
    await expect(armadaToken.connect(cruizeWallet).transfer(signer.address,parseEther("10"))).to.be.reverted;
  });

  it("Add signer as a whitelist user", async function () {
    await armadaToken.connect(admin).toggleWhitelist(signer.address);
    await armadaToken.connect(signer).transfer(cruizeWallet.address,parseEther("10"));
  });

});