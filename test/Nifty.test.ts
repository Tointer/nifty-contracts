import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { NiftyMemories } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import chai from "chai";
import { solidity } from "ethereum-waffle";

chai.use(solidity);

describe("Nifty Memories", function () {

  let niftyMemories : NiftyMemories;
  let wallet0: SignerWithAddress;
  let wallet1: SignerWithAddress;
  let wallet2: SignerWithAddress;
  let wallet3: SignerWithAddress;

  let account1Collection: Contract;
  
  const zeroAddress = "0x0000000000000000000000000000000000000000"

  beforeEach(async function () {
    const NiftyMemories = await ethers.getContractFactory("NiftyMemories");
    const SignableERC721 = await ethers.getContractFactory("SignableERC721");
    niftyMemories = await NiftyMemories.deploy();

    await niftyMemories.deployed();

    [wallet0, wallet1, wallet2, wallet3] = await ethers.getSigners();

    const accountAddress1 = await niftyMemories.connect(wallet1).callStatic.createAccount();
    await niftyMemories.connect(wallet1).createAccount();

    account1Collection = new Contract(accountAddress1, SignableERC721.interface, SignableERC721.signer);
  });

  it("Create account", async () => {
    const accountAddress0 = await niftyMemories.connect(wallet0).callStatic.createAccount();
    console.log(accountAddress0);
    await niftyMemories.connect(wallet0).createAccount();
    expect(await niftyMemories.accounts(wallet0.address)).to.equal(accountAddress0);
  });

  it("Mint with private sign", async () => {
    const signees : string[] = [wallet0.address, wallet1.address, wallet2.address];
    expect(await account1Collection.connect(wallet1).safeMintPrivateSign(1000, "", signees)).to.emit(account1Collection, "Transfer").withArgs(zeroAddress, wallet1.address, "0");
    expect(await account1Collection.connect(wallet1).safeMintPrivateSign(1000, "", signees)).to.emit(account1Collection, "RequestSign").withArgs("1", signees);
  });

  it("Mint with public sign", async () => {
    expect(await account1Collection.connect(wallet1).safeMintPublicSign(1000, "")).to.emit(account1Collection, "Transfer").withArgs(zeroAddress, wallet1.address, "0");
  });

  it("Private sign", async () => {
    const signees : string[] = [wallet0.address, wallet1.address, wallet2.address];
    await account1Collection.connect(wallet1).safeMintPrivateSign(1000, "", signees);

    expect(await account1Collection.connect(wallet2).signToken(0)).to.emit(account1Collection, "Signed").withArgs("0", wallet2.address);

    expect(await account1Collection.callStatic.getTokenSignRequests(0)).to.have.members([wallet0.address, wallet1.address]);
    expect(await account1Collection.callStatic.getTokenSignRequests(0)).to.have.length(2);

    expect(await account1Collection.callStatic.getTokenSignees(0)).to.have.members([wallet2.address]);
    expect(await account1Collection.callStatic.getTokenSignees(0)).to.have.length(1);

    expect(account1Collection.connect(wallet3).signToken(0)).to.be.revertedWith("You can't sign this");
  });

  it("Public sign", async () => {
    await account1Collection.connect(wallet1).safeMintPublicSign(1000, "123");

    expect(await account1Collection.callStatic.tokenURI(0)).to.equal("123");

    expect(await account1Collection.connect(wallet1).signToken(0)).to.emit(account1Collection, "Signed").withArgs("0", wallet1.address);
    expect(await account1Collection.callStatic.getTokenSignees(0)).to.have.members([wallet1.address]);
    expect(await account1Collection.callStatic.getTokenSignees(0)).to.have.length(1);

    expect(await account1Collection.connect(wallet2).signToken(0)).to.emit(account1Collection, "Signed").withArgs("0", wallet2.address);
    expect(await account1Collection.callStatic.getTokenSignees(0)).to.have.members([wallet1.address, wallet2.address]);
    expect(await account1Collection.callStatic.getTokenSignees(0)).to.have.length(2);
  });

  it("Public sign with 0 time", async () => {
    await account1Collection.connect(wallet1).safeMintPublicSign(1000, "");
    expect(account1Collection.connect(wallet3).signToken(0)).to.be.revertedWith("You can't sign this");
  });

});
