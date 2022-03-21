const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("../hardhat.config");

describe("Banbook", async function () {
  let banbook, token;
  let owner, addr1, addr2, ban1;

  const _initialDeployment = async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("bagicToken");
    token = await Token.deploy();
    await token.deployed();

    const Banbook = await ethers.getContractFactory("banbook");
    banbook = await Banbook.deploy(token.address);
    await banbook.deployed();
    await token.setController(banbook.address);
  };

  const _mintBanbook = async function () {
    ban1 = banbook.connect(addr1);
    const minprice = 100000000000000000n;
    await banbook.flipSalesStatus();
    await banbook.mintBanbook(5, { value: minprice });
    await ban1.mintBanbook(5, { value: minprice });
  };

  const _stakeBook = async function () {
    await banbook.stakeBook(1);
    await ban1.stakeBook(10);
  };

  beforeEach(async function () {
    await _initialDeployment();
    await _mintBanbook();
    await _stakeBook();
  });

  describe("Deployment", function () {
    it("Check if staked", async function () {
      assert.notEqual(await banbook._book(1).stakedAt, 0);
    });

    it("Check Unstake banbook", async function () {
      await banbook.unStakeBook(1);
      await ban1.unStakeBook(10);
      assert.equal(await ban1._book(10).stakedAt, undefined);
    });
  });

  describe("Transfer", async function () {
    it("Transfer when staked should be reverted", async function () {
      await expect(banbook.transferFrom(owner.address, addr1.address, 1)).to.be
        .reverted;
    });

    it("Transfer when unstaked", async function () {
      await banbook.unStakeBook(1);
      await banbook.transferFrom(owner.address, addr1.address, 1);
      assert.equal(await banbook.ownerOf(1), addr1.address);
    });
  });

  describe("Approve", async function () {
    it("Approve address1 when book is staked(revert)", async function () {
      await expect(banbook.approve(addr1.address, 1)).to.be.reverted;
    });

    it("Approve address1 and transfer after unstake book", async function () {
      await banbook.unStakeBook(1);
      await banbook.approve(addr1.address, 1);
      await ban1.transferFrom(owner.address, addr1.address, 1);
      assert.equal(await banbook.ownerOf(1), addr1.address);
    });

    it("Check approval after transfer", async function () {
      await banbook.unStakeBook(1);
      await banbook.approve(addr1.address, 1);
      await ban1.transferFrom(owner.address, addr1.address, 1);
      await expect(banbook.transferFrom(owner.address, addr1.address, 1)).to.be
        .reverted;
    });

    it("Stake and claim bagic after transfer", async function () {
      await banbook.unStakeBook(1);
      await banbook.approve(addr1.address, 1);
      await ban1.transferFrom(owner.address, addr1.address, 1);
      await ban1.stakeBook(1);
      await expect(ban1.transferFrom(addr1.address, owner.address, 1)).to.be
        .reverted; //should be reverted as book1 is staked
      await ban1.claimBagic(addr1.address);
      console.log(await token.balanceOf(addr1.address));
    });
  });

  describe("Ban function", async function () {
    it("ban address1, with - staked book and unstaked book", async function () {
      await banbook.flip(addr1.address, 1);
      const status = await banbook.addressStatus(addr1.address);
      assert.equal(await status[0], true);
      await expect(banbook.flip(addr1.address, 2)).to.be.reverted; //2 not staked
    });

    it("ban address1 and unban, count should +1 and get ashToken", async function () {
      await banbook.flip(addr1.address, 1);
      const status = await banbook.addressStatus(addr1.address);
      assert.equal(await status[0], true);
      await banbook.flip(addr1.address, 1);
      const newStatus = await banbook.addressStatus(addr1.address);
      assert.equal(await newStatus[0], false);
      assert.equal(await newStatus[2], 1);
    });

    it("banned address can't transfer/approve/stake", async function () {
      await banbook.flip(addr1.address, 1);
      await expect(ban1.transferFrom(addr1.address, owner.address, 6)).to.be
        .reverted;
      await expect(ban1.stakeBook(6)).to.be.reverted;
      // await expect(ban1.approve(owner.address, 6)).to.be.reverted;
    });
  });

  describe.only("restore book max page", async function () {
    it("First try", async function () {
      await banbook.stakeBook(2);
      await banbook.stakeBook(3);
      await banbook.stakeBook(4);
      await banbook.stakeBook(5);
      await banbook.claimBagic(owner.address);
      await banbook.restorePages(1);
    });
  });
});
