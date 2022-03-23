// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is Ownable, ERC20Burnable {

    address public specialAddress;
    address public vault;

    mapping(address => bool) private whitelist;
    mapping(address => bool) private blacklist;
    mapping(address => uint256) private _balances;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    modifier onlySpecialAddress() {
        require(specialAddress == msg.sender, "Caller is not the specialAddress for mint");
        _;
    }

    constructor (address _vault) ERC20("Token1", "TKN1") {
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBlacklisted(from), "Address in the blacklist");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        if(isWhitelisted(from)) {
            _balances[to] += amount;
        } else {
            uint256 comission = amount * 5 / 100;
            amount -= comission;
            _balances[to] += amount;
            _balances[vault] += comission;
        }
        emit Transfer(from, to, amount);
    }

    // in comments the same realisation of transfer ERC20 tokens))

    /*function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        transferWithComission(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        transferWithComission(from, to, amount);
        return true;
    }


    function transferWithComission(address from, address to, uint256 amount) internal virtual returns(bool) {
        require(!isBlacklisted(from), "Address in the blacklist");
        if(isWhitelisted(from)) {
             _transfer(from, to, amount);
        } else {
            uint256 comission = amount * 5 / 100;
            amount -= comission;
            _transfer(from, to, amount);
            _transfer(from, vault, comission);
        }
        return true;
    }*/
}
