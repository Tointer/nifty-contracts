import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { NiftyMemories } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { AbiCoder } from "ethers/lib/utils";
import { AbiHelpers } from "hardhat/src/internal/util/abi-helpers";

describe("Nifty Memories", function () {

  let niftyMemories : NiftyMemories;
  let wallet0: SignerWithAddress;
  let wallet1: SignerWithAddress;
  let wallet2: SignerWithAddress;

  let account1Collection: Contract;
  
  const zeroAddress = "0x0000000000000000000000000000000000000000"

  beforeEach(async function () {
    const NiftyMemories = await ethers.getContractFactory("NiftyMemories");
    const SignableERC721 = await ethers.getContractFactory("SignableERC721");
    niftyMemories = await NiftyMemories.deploy();

    await niftyMemories.deployed();

    const wallets = await ethers.getSigners();
    wallet0 = wallets[0];
    wallet1 = wallets[1];
    wallet2 = wallets[2];

    const accountAddress1 = await niftyMemories.connect(wallet1).callStatic.createAccount();
    await niftyMemories.connect(wallet1).createAccount();

    account1Collection = new Contract(accountAddress1, SignableERC721.interface, SignableERC721.signer);
  });

  it("Create account", async () => {
    console.log("chel");
    const accountAddress0 = await niftyMemories.connect(wallet0).callStatic.createAccount();
    console.log(accountAddress0);
    await niftyMemories.connect(wallet0).createAccount();
    console.log("bruh");
    expect(await niftyMemories.accounts(wallet0.address)).to.equal(accountAddress0);
  });

  // it("Mint without signees", async () => {
  //   const signees : string[] = [wallet1.address];
  //   expect(await account1Collection.connect(wallet1).safeMintSigneesSet(1000, signees)).to.emit(account1Collection, "Transfer").withArgs(zeroAddress, wallet1.address, "0");
  // });

  it("Mint with signees", async () => {
    const signees : string[] = [wallet0.address, wallet1.address, wallet2.address];
    expect(await account1Collection.connect(wallet1).safeMintSigneesSet(1000, signees)).to.emit(account1Collection, "Transfer").withArgs(zeroAddress, wallet1.address, "0");
    expect(await account1Collection.connect(wallet1).safeMintSigneesSet(1000, signees)).to.emit(account1Collection, "RequestSign").withArgs("1", signees);
  });

  it("Sign", async () => {
    const signees : string[] = [wallet0.address, wallet1.address, wallet2.address];
    await account1Collection.connect(wallet1).safeMintSigneesSet(1000, signees);

    expect(await account1Collection.connect(wallet2).signToken(0)).to.emit(account1Collection, "Signed").withArgs("0", wallet2.address);
    expect(await account1Collection.callStatic.getTokenSignRequests(0)).to.have.members([wallet0.address, wallet1.address]);
    expect(await account1Collection.callStatic.getTokenSignRequests(0)).to.have.length(2);
    expect(await account1Collection.callStatic.getTokenSignees(0)).to.have.members([wallet2.address]);
    expect(await account1Collection.callStatic.getTokenSignees(0)).to.have.length(1);
  });

});
