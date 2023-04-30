// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeVault is ERC20, Ownable {
    constructor() ERC20("Axora Staked ETH","asETH"){}

    function stakeETH() external payable {
        _mint(msg.sender,msg.value);
    }

    function withDrawETH(uint256 _amount) external {
        if(balanceOf(msg.sender) < _amount) revert("Not enough stake");
        _burn(msg.sender,_amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        assert(success);
    }
}