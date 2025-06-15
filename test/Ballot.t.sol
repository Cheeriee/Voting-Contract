// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/Ballot.sol";

contract BallotTest is Test {
    Ballot ballot;
    address admin = address(0x1);
    address voter1 = address(0x2);
    address nonAdmin = address(0x3);
    uint256 votingStart = block.timestamp + 1 days;
    uint256 cardExpiry = block.timestamp + 30 days;

    event CandidateAdded(uint256 indexed id, string name);
    event VotingRestrictedToGender(Ballot.Gender gender);
    event BalloterRegistered(address indexed balloter, uint256 age, bool isDisabled, Ballot.Gender gender);
    event VoteCasted(address indexed balloter, uint256 indexed candidateId);

    function setUp() public {
        vm.prank(admin);
        ballot = new Ballot(votingStart);
    }

    // Test constructor initialization
    function testConstructor() public {
        assertEq(ballot.admin(), admin, "Admin should be set");
        assertEq(ballot.votingStart(), votingStart, "Voting start should be set");
        assertFalse(ballot.votingEnded(), "Voting should not be ended");
        assertEq(ballot.candidateCount(), 0, "Candidate count should be 0");
    }

    // Test adding a candidate
    function testAddCandidate() public {
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit CandidateAdded(1, "John");
        ballot.addCandidate("John");
        assertEq(ballot.candidateCount(), 1, "Candidate count should be 1");
        (uint256 id, string memory name, uint256 votes) = ballot.candidates(1);
        assertEq(id, 1, "Candidate ID should be 1");
        assertEq(name, "John", "Candidate name should be John");
        assertEq(votes, 0, "Candidate votes should be 0");
    }

    // Test restricting voting to gender and invalid input
    function testRestrictVotingToGenderValid() public {
        vm.prank(admin);
        vm.expectEmit(false, false, false, true);
        emit VotingRestrictedToGender(Ballot.Gender.Male);
        ballot.restrictVotingToGender(Ballot.Gender.Male);
        assertTrue(ballot.hasGenderVotingRestriction(), "Gender restriction should be set");
        assertEq(uint256(ballot.votingRestrictedTo()), 0, "Voting restricted to Male");
    }

    // Test registering a balloter
    function testRegisterBalloter() public {
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit BalloterRegistered(voter1, 25, true, Ballot.Gender.Male);
        ballot.registerBalloter(voter1, true, 25, 0, true, cardExpiry);
        assertEq(ballot.balloterCount(), 1, "Balloter count should be 1");
        (address balloter, bool isDisabled, uint256 age, Ballot.Gender gender, bool valid, uint256 expiry) = ballot.balloters(voter1);
        assertEq(balloter, voter1, "Balloter address should match");
        assertTrue(isDisabled, "Balloter should be disabled");
        assertEq(age, 25, "Balloter age should be 25");
        assertEq(uint256(gender), 0, "Balloter gender should be Male");
        assertTrue(valid, "Balloter should be valid");
        assertEq(expiry, cardExpiry, "Balloter expiry should match");
    }

    // Test valid voting
    function testCastVote() public {
        vm.prank(admin);
        ballot.addCandidate("John");
        vm.prank(admin);
        ballot.registerBalloter(voter1, true, 25, 0, true, cardExpiry);
        vm.warp(votingStart + 1);
        vm.prank(voter1);
        vm.expectEmit(true, true, false, true);
        emit VoteCasted(voter1, 1);
        ballot.castVote(voter1, 1);
        assertTrue(ballot.hasVoted(voter1), "Voter should have voted");
        (,, uint256 votes) = ballot.candidates(1);
        assertEq(votes, 1, "Candidate votes should be 1");
    }

    // Test invalid voting scenarios
    function testCastVoteInvalid() public {
        vm.prank(admin);
        ballot.addCandidate("John");
        vm.prank(admin);
        ballot.registerBalloter(voter1, true, 25, 0, true, cardExpiry);
        vm.warp(votingStart + 1);

        // Unregistered voter 
        vm.prank(voter1);
        vm.expectRevert(Ballot.InvalidCard.selector);
        ballot.castVote(address(0x6), 1);

        // Expired card
        address expiredVoter = address(0x7);
        vm.prank(admin);
        uint256 shortExpiry = block.timestamp + 1;
        ballot.registerBalloter(expiredVoter, true, 25, 0, true, shortExpiry);
        vm.warp(shortExpiry + 1);
        vm.prank(expiredVoter);
        vm.expectRevert(Ballot.CardExpired.selector);
        ballot.castVote(expiredVoter, 1);

        // Expiry equals block.timestamp
        address edgeVoter = address(0x8);
        vm.prank(admin);
        uint256 nowExpiry = block.timestamp;
        ballot.registerBalloter(edgeVoter, true, 25, 0, true, nowExpiry);
        vm.prank(edgeVoter);
        vm.expectRevert(Ballot.CardExpired.selector);
        ballot.castVote(edgeVoter, 1);
    }

    // Test retrieving results
    function testGetResults() public {
        vm.prank(admin);
        ballot.addCandidate("John");
        Ballot.Candidate[] memory results = ballot.getResults();
        assertEq(results.length, 1, "Results should have 1 candidate");
        assertEq(results[0].id, 1, "Candidate ID should be 1");
        assertEq(results[0].name, "John", "Candidate name should be John");
        assertEq(results[0].votes, 0, "Candidate votes should be 0");
    }

    // Test getting winner
    function testGetWinner() public {
        vm.prank(admin);
        ballot.addCandidate("John");
        vm.prank(admin);
        ballot.registerBalloter(voter1, true, 25, 0, true, cardExpiry);
        vm.warp(votingStart + 1);
        vm.prank(voter1);
        ballot.castVote(voter1, 1);
        vm.prank(admin);
        ballot.endVoting();
        (uint256 id, string memory name, uint256 votes) = ballot.getWinner();
        assertEq(id, 1, "Winner ID should be 1");
        assertEq(name, "John", "Winner name should be John");
        assertEq(votes, 1, "Winner votes should be 1");
    }
}