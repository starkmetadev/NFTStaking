/* eslint-disable prettier/prettier */
import { expect } from "chai";
import { BigNumber, Wallet, utils } from "ethers";
import hre, { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";

let RewardTokenContract: any;
let RewardTokenFactory;

let NFTStakingContract: any;
let NFTStakingFactory;

let NFTContract: any;
let NFTContractFactory;

let wallet: Wallet;
let referrer1: Wallet;
let referrer2: Wallet;
let cakeWallet: Wallet;
let squadWallet: Wallet;
let user3: Wallet;
let user1: Wallet;
let user2: Wallet;
let user4: Wallet;
let devWallet: Wallet;

// Start test block
describe("NFT staking", function () {
  before(async function () {
    console.log("---------------");
    [
      wallet,
      referrer1,
      referrer2,
      cakeWallet,
      squadWallet,
      user3,
      user1,
      user2,
      user4,
      devWallet,
    ] = await (ethers as any).getSigners();

    RewardTokenFactory = await ethers.getContractFactory("MockERC20");
    RewardTokenContract = await  RewardTokenFactory.deploy();

    NFTContractFactory = await ethers.getContractFactory("MockNFT");
    NFTContract = await  NFTContractFactory.deploy();

    NFTStakingFactory = await ethers.getContractFactory("NFTStaking");
    NFTStakingContract = await NFTStakingFactory.deploy(
      RewardTokenContract.address,
      NFTContract.address
    );

    await RewardTokenContract.transfer(NFTStakingContract.address, utils.parseEther("100000000"))

    
  });

  // Test case

  it("Claim rewards calculation", async function () {

    await NFTStakingContract.connect(user1).mintToken(user1.address, "user1")
    await NFTStakingContract.connect(user1).mintToken(user1.address, "user1")
    await NFTStakingContract.connect(user2).mintToken(user1.address, "user1")
    await NFTStakingContract.connect(user3).mintToken(user1.address, "user1")

    let increaseTo = await time.latest();
    increaseTo += 3600 * 24 * 4;
    await time.increaseTo(increaseTo);
    
  });
});
