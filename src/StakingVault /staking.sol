// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract stakingContract is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ERC20Permit, ERC20Votes {
    constructor() ERC20("Bridgus", "BRDG") ERC20Permit("Bridgus") {
        _mint(address(this), 100000000 );
    }
     
      //mapping keeps record of every account
        mapping(address => uint256) public rewardBalance;
        mapping(address => uint256) public ETHbalance;
        mapping(address => uint256) public TokenBalance;

       //Timestamp to start staking
       uint256 public startTime = block.timestamp + (86400 * 365);
       function startStakingTime(uint256 value) public onlyOwner{
       startTime = block.timestamp + value;
       } 
       
        //logic to stop staking
          uint256 public stopStaking1 = 25042023;
          uint256 public stopStaking2 = 25042023;
          function stopStakingProcess1(uint256 value) public onlyOwner {
            stopStaking1 = value;
          }
          function stopStakingProcess2(uint256 value) public onlyOwner {
            stopStaking2 = value;
          }

        //timestamp for withdrawals
        uint256 public withdrawTime = block.timestamp + (86400 * 365);
       function scheduleWithdraw(uint256 value) public onlyOwner {
       withdrawTime = block.timestamp + value;
       }
      
      //to stake with Ether
       function stakeWithEther() public payable {
         require(block.timestamp > startTime, "Staking has not started!");
          require(stopStakingProcess1 == stopStakingProcess2, "Staking is yet to start!");
          require(msg.value > 0, "You cannot stake 0 ETH");
          ETHbalance[msg.sender] += msg.value;
          rewardBalance[msg.sender] += msg.value * 2400;
           }
       
      //to stake with other tokens 
    function stakeWithOtherTokens(address _tokenContractAddress, uint256 theAmount) internal {
       require(block.timestamp > startTime, "Staking has not started!");
        require(stopStakingProcess1 == stopStakingProcess2, "Staking is yet to start!");
        IERC20(_tokenContractAddress).transferFrom(msg.sender, address(this), theAmount);
         TokenBalance[msg.sender] += theAmount;
         rewardBalance[msg.sender] += theAmount * 2;
        }
        function stakeWithDAI(uint256 theAmount) public {
        stakeWithOtherTokens(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, theAmount);
       }
        function stakeWithUSDT(uint256 theAmount) public {
        stakeWithOtherTokens(0x55d398326f99059fF775485246999027B3197955, theAmount);
        }

    //to withdraw your rewards
    function userWithdrawReward(address yourAddress, uint256 amount) external {
        require(block.timestamp >= withdrawTime, "Tokens withdrawal has not started");
         require(rewardBalance[msg.sender] >= amount, "Insufficient tokens balance");
         _transfer(address(this), yourAddress, amount);
         rewardBalance[msg.sender] -= amount ;
         }

    //to withdraw your deposited Ether
   function userWithdrawEther(address payable inputAddress, uint amount) external{
      require(block.timestamp >= withdrawTime, "ETH withdrawal has not started");
      require(ETHbalance[msg.sender] >= amount, "Insufficient balance");
     (bool success,) = inputAddress.call{value:amount}("");
     require(success, "the transaction has failed");
     ETHbalance[msg.sender] -= amount;
     } 

   //to withdraw all your deposited tokens, remember to input their contract addresses
    function userWithdrawOtherTokens(address _tokenContractAddress, address yourAddress, uint256 amount) external{
     require(block.timestamp >= withdrawTime, "ETH withdrawal has not started");
     require(TokenBalance[msg.sender] >= amount, "Insufficient balance");
     IERC20(_tokenContractAddress).transfer(yourAddress, amount);
      TokenBalance[msg.sender] -= amount;
    }   


   //will show Ether balance of the contract
   function showBalance() external view returns (uint){
    return address(this).balance;
   }

   // to make the contract send out ether... to be done by only the admin
function sendOutEther(address payable inputAddress, uint amount) external onlyOwner{
    (bool success,) = inputAddress.call{value:amount}("");
    require(success, "the transaction has failed");
}

//to make the contract send out other deposited tokens..... to be done by only the admin
   function sendOutOtherTokens(address _tokenContractAddress, address _receivingAddress, uint256 theAmount) public onlyOwner {
        IERC20(_tokenContractAddress).transfer(_receivingAddress, theAmount);
   }
   //STAKING LOGIC ENDS HERE........    




    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
