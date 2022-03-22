//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Vault is Ownable, IERC20 {

    function withdraw(address to, uint256 _amount) public onlyOwner {
       owner.transfer(to, _amount);
    }
}
