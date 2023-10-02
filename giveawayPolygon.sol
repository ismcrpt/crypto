// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the library for working with MATIC
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CustomSplitter {
    uint256 public contractBalance;
    address public owner;
    uint256 public totalParticipants;
    uint256 public numberOfWinners;
    uint256 public creatorFeePercentage = 0.8; // Creator's fee percentage (0.8% = 0.008)

    address[] public winners;
    bool public roundInProgress;

    mapping(address => uint256) public userBalances;

    // Address of the MATIC token on the Polygon (Matic) network
    address public maticTokenAddress = 0xADDRESS_OF_MATIC_TOKEN;

    constructor(uint256 _totalParticipants, uint256 _numberOfWinners) {
        owner = msg.sender;
        totalParticipants = _totalParticipants;
        numberOfWinners = _numberOfWinners;
        roundInProgress = true;
    }

    // Function to deposit MATIC into the contract
    function deposit() public payable {
        require(msg.value == 0, "Use the transferMATIC function to deposit MATIC");
    }

    // Function to transfer MATIC
    function transferMATIC(uint256 amount) public {
        require(amount > 0, "You must send some MATIC");
        
        // Ensure that the user sends MATIC to the correct contract address
        require(msg.sender == address(this), "Send MATIC to the contract address");
        
        // Transfer MATIC to the contract's balance
        IERC20(maticTokenAddress).transferFrom(msg.sender, address(this), amount);
        
        userBalances[msg.sender] += amount;
        contractBalance += amount;
    }

    function split() public {
        require(roundInProgress, "The current round has ended");
        require(userBalances[msg.sender] > 0, "You don't have a balance to split");

        uint256 userBalance = userBalances[msg.sender];
        require(userBalance > 0, "You don't have enough balance to split");

        require(winners.length < numberOfWinners, "All winners are already determined");

        // Total pot of participants' contributions
        uint256 totalPot = contractBalance;

        // Total balance of the winners
        uint256 totalWinnersBalance = 0;
        for (uint256 i = 0; i < winners.length; i++) {
            totalWinnersBalance += userBalances[winners[i]];
        }

        // Calculate the distribution factor
        uint256 distributionFactor = ((totalPot * 100) - (creatorFeePercentage * totalPot)) / totalWinnersBalance;

        // Calculate the user's share proportionally to their balance
        uint256 userShare = (userBalance * distributionFactor) / 100;

        userBalances[msg.sender] -= userBalance;
        contractBalance -= userBalance;

        // Send the winnings in MATIC
        IERC20(maticTokenAddress).transfer(msg.sender, userShare);

        winners.push(msg.sender);

        if (winners.length == numberOfWinners) {
            roundInProgress = false;
            uint256 creatorFee = (contractBalance * creatorFeePercentage) / 100;
            IERC20(maticTokenAddress).transfer(owner, creatorFee); // Send the creator's fee
            autoReset();
        }
    }

    function autoReset() public {
        require(!roundInProgress, "Round is still in progress");
        roundInProgress = true;
        reset();
    }

    function reset() internal {
        contractBalance = 0;
        for (uint256 i = 0; i < winners.length; i++) {
            userBalances[winners[i]] = 0;
        }
        delete winners;
    }
}
