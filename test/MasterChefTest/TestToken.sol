// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract TokenContract is ERC20("Test Token", "TST"), Ownable {
    function mint(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}