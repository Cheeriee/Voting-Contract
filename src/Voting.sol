// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Voting {
    address public admin;
    uint256 public votingStart;
    bool public votingEnded;

   struct VoterCard{
    uint256 age;
    uint256 expiry;
    address owner;
    bool isIssued;
   }

   struct Candidate{
    uint256 id;
    string name;
    uint256 votes;
   }

   mapping(address => VoterCard) public voterCards;
   mapping(uint256 => Candidate) public candidates;
   mapping(address => bool) public hasVoted;
   uint256 public candidateCount; 

   event CardIssued(address voter);
   event CandidateAdded(uint256 candidateId, string name);
   event Voted(address voter, uint256 candidateId);
   event VotingEnded();


   error NotAdmin();
   error NotEligibleAge();
   error CardNOTValid();
   error AlreadyVoted();
   error NotCardOwner();
   error VotingNotStarted();
   error VotingAlreadyEnded();
   error CandidateDoesNotExist();

   constructor(uint256 _startTimestamp) {
    admin = msg.sender;
    votingStart = _startTimestamp;
   }

   modifier onlyAdmin() {
    if(msg.sender != admin) revert NotAdmin();
    _;
   }

   modifier votingOpen() {
    if(block.timestamp < votingStart) revert VotingNotStarted();
    if(votingEnded) revert VotingAlreadyEnded();
    _;
   }

   function issueCard(address voter, uint256 age, uint256 expiry) external onlyAdmin{
    voterCards[voter] = VoterCard({
        age: age, 
        expiry: expiry,
        owner: voter,
        isIssued: true
    });
    emit CardIssued(voter);
   }

   function addCandidate(string memory name) external onlyAdmin {
    candidateCount++;
    candidates[candidateCount] = Candidate({
        id: candidateCount,
        name: name,
        votes: 0
    });

    emit CandidateAdded(candidateCount, name);
   }

   function vote(uint256 candidateId) external votingOpen {
        VoterCard memory card = voterCards[msg.sender];

        if (!card.isIssued || card.age < 18) revert NotEligibleAge();
        if (card.expiry < block.timestamp) revert CardNOTValid();
        if (card.owner != msg.sender) revert NotCardOwner();
        if (hasVoted[msg.sender]) revert AlreadyVoted();
        if (candidateId == 0 || candidateId > candidateCount) revert CandidateDoesNotExist();

        candidates[candidateId].votes++;
        hasVoted[msg.sender] = true;
        emit Voted(msg.sender, candidateId);
    }

    function endVoting() external onlyAdmin {
        votingEnded = true;
        emit VotingEnded();
    }

    function getCandidate(uint256 id) external view returns (string memory name, uint256 votes) {
        Candidate memory candidate = candidates[id];
        return (candidate.name, candidate.votes);
    }

    function getAllCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory list = new Candidate[](candidateCount);
        for (uint256 i = 1; i <= candidateCount; i++) {
            list[i - 1] = candidates[i];
        }
        return list;
    }

    function hasVoterVoted(address voter) external view returns (bool) {
        return hasVoted[voter];
    }
}















































   
