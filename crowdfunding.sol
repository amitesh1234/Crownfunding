// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

contract CrowdFunding {
    address public projectCreator;
    uint private amountRaised = 0; // amount of ETH raised till now
    uint public fundingGoal;
    uint public conversionRate;
    uint public totalTokenSupply; //total SM tokens I am willing to give out using this crowdfunding

    bool public isWithdrawalInitiated = false; //investor who have put in the ETH can now withdraw the SM tokens?
    IERC20 public tokenContract;
    uint public fundsRaised;
    uint public fundsWithdrawan = 0;
    bool public isFunded = false;
    mapping(address => uint) tokensAssignedMapping;

    constructor(uint _fundingGoalInWei, uint _conversionRate, address _tokenContractAddress) {
        projectCreator = msg.sender;
        fundingGoal = _fundingGoalInWei;
        conversionRate = _conversionRate;
        tokenContract = IERC20(_tokenContractAddress);
    }

    modifier onlyOwner() {
        require(projectCreator == msg.sender, "Ownable: Not allowed");
        _;
    }
    //funding goal: 10ETH, conversionRate = 10SM (1etH = 10SM), 10 ETH * 10sm = 100sm
    function fundContract() public onlyOwner {
        require(isFunded == false, "Already Funded");
        uint tokenAmount = fundingGoal * conversionRate;
        uint balance = tokenContract.balanceOf(address(this));
        require(balance >= tokenAmount, "Insufficient tokens");
        isFunded = true;
    }

    function isFundingGoalReached() public view returns(bool) {
        return fundsRaised >= fundingGoal;
    }

    function editWithdrawal(bool _initiated) public onlyOwner {
        isWithdrawalInitiated = _initiated;
    }

    function contribute() public payable{
        require(isFunded == true, "Not started yet");
        require(!isFundingGoalReached(), "Funding Goal Attained");
        require(fundsRaised + msg.value <= fundingGoal, "Send less amount");
        require(msg.value > 0, "Insufficient eth sent");

        tokensAssignedMapping[msg.sender] += msg.value;
        fundsRaised += msg.value;
    }

    function withdrawToken() public {
        require(isWithdrawalInitiated, "Withdrawals not initiated yet");
        require(tokensAssignedMapping[msg.sender] > 0, "No tokens assigned");
        
        require(tokenContract.transfer(msg.sender, tokensAssignedMapping[msg.sender] * conversionRate), "transfer failed");
        tokensAssignedMapping[msg.sender] = 0;
    }


    function withdrawEth() public onlyOwner{
        require(fundsRaised - fundsWithdrawan > 0, "Already withdrawn everything");
        fundsWithdrawan += fundsRaised;
        (bool sent, ) = projectCreator.call{value: fundsRaised}(" ");
        require(sent, "Transfer not successful");
    }


}

