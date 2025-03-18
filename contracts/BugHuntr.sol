// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BugHuntr is Ownable, ReentrancyGuard {
    // Structs
    struct BugReport {
        address reporter;
        string description;
        string proofOfConcept;
        uint256 timestamp;
        uint256 severity; // 1-5
        uint256 reward;
        bool isApproved;
        bool isRejected;
        bool isClaimed;
    }

    // State variables
    uint256 public reportCount;
    mapping(uint256 => BugReport) public bugReports;
    mapping(address => uint256[]) public userReports;
    mapping(uint256 => uint256) public severityRewards; // severity level => reward amount
    uint256 public totalRewardsPaid;
    IERC20 public rewardToken;

    // Events
    event BugReportSubmitted(uint256 indexed reportId, address indexed reporter);
    event BugReportApproved(uint256 indexed reportId, uint256 severity, uint256 reward);
    event BugReportRejected(uint256 indexed reportId);
    event RewardClaimed(uint256 indexed reportId, address indexed reporter, uint256 amount);
    event FundsDeposited(uint256 amount);
    event SeverityRewardUpdated(uint256 severity, uint256 newReward);

    // Modifiers
    modifier reportExists(uint256 _reportId) {
        require(_reportId < reportCount, "Report does not exist");
        _;
    }

    modifier reportNotProcessed(uint256 _reportId) {
        require(!bugReports[_reportId].isApproved && !bugReports[_reportId].isRejected, "Report already processed");
        _;
    }

    modifier reportApproved(uint256 _reportId) {
        require(bugReports[_reportId].isApproved, "Report not approved");
        _;
    }

    modifier reportNotClaimed(uint256 _reportId) {
        require(!bugReports[_reportId].isClaimed, "Reward already claimed");
        _;
    }

    constructor(address _rewardToken) Ownable(msg.sender) {
        rewardToken = IERC20(_rewardToken);
        
        // Initialize default severity rewards
        severityRewards[1] = 100 * 10**18; // 100 tokens
        severityRewards[2] = 250 * 10**18; // 250 tokens
        severityRewards[3] = 500 * 10**18; // 500 tokens
        severityRewards[4] = 1000 * 10**18; // 1000 tokens
        severityRewards[5] = 2000 * 10**18; // 2000 tokens
    }

    // Functions
    function submitBugReport(string memory _description, string memory _proofOfConcept) external {
        uint256 reportId = reportCount++;
        BugReport storage report = bugReports[reportId];
        
        report.reporter = msg.sender;
        report.description = _description;
        report.proofOfConcept = _proofOfConcept;
        report.timestamp = block.timestamp;
        
        userReports[msg.sender].push(reportId);
        
        emit BugReportSubmitted(reportId, msg.sender);
    }

    function approveBugReport(uint256 _reportId, uint256 _severity) 
        external 
        onlyOwner 
        reportExists(_reportId) 
        reportNotProcessed(_reportId) 
    {
        require(_severity >= 1 && _severity <= 5, "Invalid severity level");
        
        BugReport storage report = bugReports[_reportId];
        report.isApproved = true;
        report.severity = _severity;
        report.reward = severityRewards[_severity];
        
        emit BugReportApproved(_reportId, _severity, report.reward);
    }

    function rejectBugReport(uint256 _reportId) 
        external 
        onlyOwner 
        reportExists(_reportId) 
        reportNotProcessed(_reportId) 
    {
        BugReport storage report = bugReports[_reportId];
        report.isRejected = true;
        
        emit BugReportRejected(_reportId);
    }

    function claimReward(uint256 _reportId) 
        external 
        nonReentrant 
        reportExists(_reportId) 
        reportApproved(_reportId) 
        reportNotClaimed(_reportId) 
    {
        BugReport storage report = bugReports[_reportId];
        require(report.reporter == msg.sender, "Not the report owner");
        
        report.isClaimed = true;
        totalRewardsPaid += report.reward;
        
        require(rewardToken.transfer(msg.sender, report.reward), "Reward transfer failed");
        
        emit RewardClaimed(_reportId, msg.sender, report.reward);
    }

    function depositFunds(uint256 _amount) external onlyOwner {
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit FundsDeposited(_amount);
    }

    function updateSeverityReward(uint256 _severity, uint256 _newReward) external onlyOwner {
        require(_severity >= 1 && _severity <= 5, "Invalid severity level");
        severityRewards[_severity] = _newReward;
        emit SeverityRewardUpdated(_severity, _newReward);
    }

    // View functions
    function getBugReport(uint256 _reportId) external view returns (
        address reporter,
        string memory description,
        string memory proofOfConcept,
        uint256 timestamp,
        uint256 severity,
        uint256 reward,
        bool isApproved,
        bool isRejected,
        bool isClaimed
    ) {
        BugReport storage report = bugReports[_reportId];
        return (
            report.reporter,
            report.description,
            report.proofOfConcept,
            report.timestamp,
            report.severity,
            report.reward,
            report.isApproved,
            report.isRejected,
            report.isClaimed
        );
    }

    function getUserReports(address _user) external view returns (uint256[] memory) {
        return userReports[_user];
    }

    function getContractBalance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
} 