//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    address public ownerVault;

    constructor() {
        ownerVault = msg.sender;
    }

    function withdraw(uint256 _amount) public onlyOwner {
       payable(ownerVault).transfer(_amount);
    }
}
