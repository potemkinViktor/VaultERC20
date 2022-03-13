const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Token", async function () {
    let Token, token, owner, vault, user1, user2;

    beforeEach("Token", async function () {
        [owner, vault, user1, user2] = await ethers.getSigners(); //подписываем переменные, они получают адрес и теперь могут взаимодействовать с нашим контрактом
        Token = await ethers.getContractFactory('Token'); 
        token = await Token.deploy(vault.address);
        await token.deployed();
    });

    describe("Deployment is correct", async function () {
        it("Deployment is correct", async function () {
            await expect(await token.deployer()).to.equal(owner.address);
            await expect(await token.vault()).to.equal(vault.address);
            await expect(await token.isWhitelisted(owner.address)).to.equal(true);
        });
    });

    describe("setSpecialAddress", async function () {
        it("Not owner sets special address", async function () {
            await expect(token.connect(user2).setSpecialAddress(user1.address)).to.be.reverted;
        });

        it("Owner sets special address", async function () {
            await expect(await token.specialAddress()).to.equal(ethers.constants.AddressZero);
            await token.setSpecialAddress(user1.address);
            await expect(await token.specialAddress()).to.equal(user1.address);
        });
    });
    
    describe("addWhitelist", async function () {
        it("Not owner adds whitelist", async function () {
            await expect(token.connect(user2).addWhitelist(user1.address)).to.be.reverted;
        });

        it("Owner adds whitelist", async function () {
            await expect(await token.isWhitelisted(user1.address)).to.equal(false);
            await token.addWhitelist(user1.address);
            await expect(await token.isWhitelisted(user1.address)).to.equal(true);
        });
    });

    describe("removeWhitelist", async function () {
        it("Not owner removes whitelist", async function () {
            await expect(await token.isWhitelisted(user1.address)).to.equal(false);
            await token.addWhitelist(user1.address);
            await expect(await token.isWhitelisted(user1.address)).to.equal(true);
            await expect(token.connect(user2).removeWhitelist(user1.address)).to.be.reverted;
        });

        it("Owner removes whitelist", async function () {
            await expect(await token.isWhitelisted(user1.address)).to.equal(false);
            await token.addWhitelist(user1.address);
            await expect(await token.isWhitelisted(user1.address)).to.equal(true);
            await token.removeWhitelist(user1.address);
            await expect(await token.isWhitelisted(user1.address)).to.equal(false);
        });
    });

    describe("addBlacklist", async function () {
        it("Not owner adds blacklist", async function () {
            await expect(token.connect(user2).addBlacklist(user1.address)).to.be.reverted;
        });

        it("Owner adds blacklist", async function () {
            await expect(await token.isBlacklisted(user1.address)).to.equal(false);
            await token.addBlacklist(user1.address);
            await expect(await token.isBlacklisted(user1.address)).to.equal(true);
        });
    });

    describe("removeBlacklist", async function () {
        it("Not owner removes blacklist", async function () {
            await expect(await token.isBlacklisted(user1.address)).to.equal(false);
            await token.addBlacklist(user1.address);
            await expect(await token.isBlacklisted(user1.address)).to.equal(true);
            await expect(token.connect(user2).removeBlacklist(user1.address)).to.be.reverted;
        });

        it("Owner removes blacklist", async function () {
            await expect(await token.isBlacklisted(user1.address)).to.equal(false);
            await token.addBlacklist(user1.address);
            await expect(await token.isBlacklisted(user1.address)).to.equal(true);
            await token.removeBlacklist(user1.address);
            await expect(await token.isBlacklisted(user1.address)).to.equal(false);
        });
    });

    describe("mint", async function () {
        it("Not special address mints", async function () {
            await expect(token.connect(user2).mint(user1.address, 1000)).to.be.reverted;
        });

        it("Special address mints", async function () {
            await expect(await token.specialAddress()).to.equal(ethers.constants.AddressZero);
            await token.setSpecialAddress(user1.address);
            await expect(await token.specialAddress()).to.equal(user1.address);
            await expect(await token.totalSupply()).to.equal(0);
            await token.connect(user1).mint(user2.address, 1000);
            await expect(await token.totalSupply()).to.equal(1000);
            await expect(await token.balanceOf(user2.address)).to.equal(1000);
        });
    });

    describe("transferWithCommission", async function () {
        beforeEach("Mint to user1", async function () {
            await token.setSpecialAddress(user1.address);
            await token.connect(user1).mint(user1.address, 1000);
        });

        it("Address in the blacklist", async function () {
            await token.addBlacklist(user1.address);
            await expect(token.transferWithCommission(user2.address, 1000)).to.be.reverted;
        });

        it("Address in the whitelist", async function () {
            await token.addWhitelist(user1.address);
            await expect(await token.balanceOf(user1.address)).to.equal(1000);
            await expect(await token.balanceOf(user2.address)).to.equal(0);
            await token.connect(user1).transferWithCommission(user2.address, 500);
            await expect(await token.balanceOf(user1.address)).to.equal(500);
            await expect(await token.balanceOf(user2.address)).to.equal(500);
        });

        it("Address is not in the whitelist", async function () {
            await expect(await token.balanceOf(user1.address)).to.equal(1000);
            await expect(await token.balanceOf(user2.address)).to.equal(0);
            await token.connect(user1).transferWithCommission(user2.address, 500);
            await expect(await token.balanceOf(user1.address)).to.equal(500);
            await expect(await token.balanceOf(user2.address)).to.equal(475);
            await expect(await token.balanceOf(vault.address)).to.equal(25);
        });
    });

    describe("transferFromWithCommission", async function () {
        beforeEach("Mint and approve", async function () {
            await token.setSpecialAddress(user1.address);
            await token.connect(user1).mint(user1.address, 2000);
            await token.connect(user1).approve(user2.address, 2000);
        });

        it("Address in the blacklist", async function () {
            await token.addBlacklist(user1.address);
            await expect(token.connect(user2).transferFromWithCommission(user1.address, owner.address, 1000)).to.be.reverted;
        });

        it("Address in the whitelist", async function () {
            await token.addWhitelist(user1.address);
            await expect(await token.balanceOf(user1.address)).to.equal(2000);
            await expect(await token.balanceOf(owner.address)).to.equal(0);
            await token.connect(user2).transferFromWithCommission(user1.address, owner.address, 500);
            await expect(await token.balanceOf(user1.address)).to.equal(1500);
            await expect(await token.balanceOf(owner.address)).to.equal(500);
        });

        it("Address is not in the whitelist", async function () {
            await expect(await token.balanceOf(user1.address)).to.equal(2000);
            await expect(await token.balanceOf(owner.address)).to.equal(0);
            await token.connect(user2).transferFromWithCommission(user1.address, owner.address, 500);
            await expect(await token.balanceOf(user1.address)).to.equal(1500);
            await expect(await token.balanceOf(owner.address)).to.equal(475);
            await expect(await token.balanceOf(vault.address)).to.equal(25);
        });
    });
    
})
