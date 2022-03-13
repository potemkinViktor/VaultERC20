// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is Ownable, ERC20, ERC20Burnable {

    address public deployer;
    address public specialAddress;
    address public vault;

    mapping(address => bool) private whitelist;
    mapping(address => bool) private blacklist;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    modifier onlySpecialAddress() {
        require(specialAddress == msg.sender, "Caller is not the specialAddress for mint");
        _;
    }

    constructor (address _vault) ERC20("Token1", "TKN1") {
        deployer = msg.sender;
        vault = _vault;
        whitelist[msg.sender] = true;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    function isBlacklisted(address _address) public view returns(bool) {
        return blacklist[_address];
    }

    function setSpecialAddress(address _specialAddress) public onlyOwner {
        specialAddress = _specialAddress;
    }

    function addWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function addBlacklist(address _address) public onlyOwner {
        blacklist[_address] = true;
        emit AddedToBlacklist(_address);
    }

    function removeBlacklist(address _address) public onlyOwner {
        blacklist[_address] = false;
        emit RemovedFromBlacklist(_address);
    }

    function mint(address account, uint256 amount) external onlySpecialAddress {
        _mint(account, amount);
    }

    function transferWithCommission(address to, uint256 amount) public virtual returns (bool) {
        address _msgSender = msg.sender;
        require(!isBlacklisted(_msgSender), "Address in the blacklist");
        if(isWhitelisted(_msgSender)) {
            transfer(to, amount);
        } else {
            uint256 comission = amount * 5 / 100;
            amount -= comission;
            transfer(to, amount);
            transfer(vault, comission);
        }
        return true;
    }

    function transferFromWithCommission(address from, address to, uint256 amount) public virtual returns (bool) {
        require(!isBlacklisted(from), "Address in the blacklist");
        if(isWhitelisted(from)) {
            transferFrom(from, to, amount);
        } else {
            uint256 comission = amount * 5 / 100;
            amount -= comission;
            transferFrom(from, to, amount);
            transferFrom(from, vault, comission);
        }
        return true;
    }
}