/* eslint-disable prettier/prettier */
import { expect } from "chai";
import { BigNumber, Wallet, utils } from "ethers";
import hre, { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";

let RewardTokenContract: any;
let RewardTokenFactory;

let StarkNFTContract: any;
let StarkNFTFactory;

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
describe("NFT Mint", function () {
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

    StarkNFTFactory = await ethers.getContractFactory("StarkNFT");
    StarkNFTContract = await StarkNFTFactory.deploy(
      RewardTokenContract.address,
      devWallet.address
    );
    await RewardTokenContract.transfer(user1.address, utils.parseEther("100000"))
    await RewardTokenContract.transfer(user2.address, utils.parseEther("100000"))
    await RewardTokenContract.transfer(user3.address, utils.parseEther("100000"))
  });

  // Test case

  it("set config", async function () {
    await StarkNFTContract.setUri("https://test.com/")
    await StarkNFTContract.setTokenPrice("1", utils.parseEther('100'));
    await StarkNFTContract.setTokenPrice("2", utils.parseEther('200'));
    await StarkNFTContract.setTokenPrice("3", utils.parseEther('300'));
    await StarkNFTContract.setTokenPrice("4", utils.parseEther('400'));
    await StarkNFTContract.setTokenPrice("5", utils.parseEther('500'));
    await StarkNFTContract.setTokenPrice("6", utils.parseEther('600'));
    await StarkNFTContract.setNFTManager(user2.address)
  });

  it("minting nfts", async function () {
    await RewardTokenContract.connect(user1).approve(StarkNFTContract.address, utils.parseEther("1000000"))
    await RewardTokenContract.connect(user2).approve(StarkNFTContract.address, utils.parseEther("1000000"))
    await RewardTokenContract.connect(user3).approve(StarkNFTContract.address, utils.parseEther("1000000"))
    await StarkNFTContract.connect(user1).mint("1")
    await StarkNFTContract.connect(user1).mint("2")
    await StarkNFTContract.connect(user1).mint("1")
    await StarkNFTContract.connect(user1).mint("1")
    await StarkNFTContract.connect(user2).mint("1")
    await StarkNFTContract.connect(user2).mint("1")
    await StarkNFTContract.connect(user3).mint("1")
    expect(await StarkNFTContract.tokenURI(1)).to.eq("https://test.com/1")
    expect(await StarkNFTContract.tokenURI(2)).to.eq("https://test.com/2")
    expect(await StarkNFTContract.tokenURI(3)).to.eq("https://test.com/1")
    expect(await StarkNFTContract.tokenURI(4)).to.eq("https://test.com/1")
    expect(await StarkNFTContract.tokenURI(5)).to.eq("https://test.com/1")
    expect(await StarkNFTContract.tokenURI(6)).to.eq("https://test.com/1")
    expect(await StarkNFTContract.tokenURI(7)).to.eq("https://test.com/1")

    console.log(await StarkNFTContract.getTokenIds(user1.address))

    await StarkNFTContract.connect(user2).burn("2")
    console.log(await StarkNFTContract.getTokenIds(user1.address))
  });
});
