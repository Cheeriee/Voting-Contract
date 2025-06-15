// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Ballot {
    address public admin;
    uint256 public votingStart;
    bool public votingEnded;
    bool public hasGenderVotingRestriction;
    Gender public votingRestrictedTo;
    uint256 public candidateCount;
    uint256 public balloterCount;

    error InvalidCard();
    error CardExpired();
    error InvalidGender();
    error NotAdmin();
    error VotingHasNotEnded();
    error CandidateNotFound();

    enum Gender { 
        Male, 
        Female }

    struct Candidate {
        uint256 id;
        string name;
        uint256 votes;
    }

    struct Balloter {
        address balloter;
        bool isDisabled;
        uint256 age;
        Gender gender;
        bool valid;
        uint256 expiry;
    }

    event CandidateAdded(uint256 indexed id, string name);
    event VotingRestrictedToGender(Ballot.Gender gender);
    event BalloterRegistered(address indexed balloter, uint256 age, bool isDisabled, Ballot.Gender gender);
    event VoteCasted(address indexed balloter, uint256 indexed candidateId);

    mapping(uint256 => Candidate) public candidates;
    mapping(address => Balloter) public balloters;
    mapping(address => bool) public hasVoted;

    constructor(uint256 _votingStart) {
        admin = msg.sender;
        votingStart = _votingStart;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    function addCandidate(string memory _name) public onlyAdmin {
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
        emit CandidateAdded(candidateCount, _name);
    }

    function restrictVotingToGender(Gender _gender) public onlyAdmin {
        if (_gender != Gender.Male && _gender != Gender.Female) {
            revert InvalidGender();
            }
        votingRestrictedTo = _gender;
        hasGenderVotingRestriction = true;
        emit VotingRestrictedToGender(_gender);
    }

    function registerBalloter(
        address _balloter,
        bool _isDisabled,
        uint256 _age,
        uint8 _gender,
        bool _valid,
        uint256 _expiry
    ) public onlyAdmin {
        balloters[_balloter] = Balloter(_balloter, _isDisabled, _age, Gender(_gender), _valid, _expiry);
        balloterCount++;
        emit BalloterRegistered(_balloter, _age, _isDisabled, Gender(_gender));
    }

    function castVote(address _balloter, uint256 _candidateId) public {
        Balloter memory balloter = balloters[_balloter];
        if (!balloter.valid) {
            revert InvalidCard();
        }
        if (balloter.expiry <= block.timestamp) {
            revert CardExpired();
        }
        if (hasVoted[_balloter]) {
            revert();
        }
        if (_candidateId == 0 || _candidateId > candidateCount) {
            revert CandidateNotFound();
        }
        candidates[_candidateId].votes++;
        hasVoted[_balloter] = true;
        emit VoteCasted(_balloter, _candidateId);
    }

    function endVoting() public onlyAdmin {
        votingEnded = true;
    }

    function getResults() public view returns (Candidate[] memory) {
        Candidate[] memory result = new Candidate[](candidateCount);
        for (uint256 i = 1; i <= candidateCount; i++) {
            result[i - 1] = candidates[i];
        }
        return result;
    }

    function getWinner() public view returns (uint256 candidateId, string memory name, uint256 votes) {
        if (!votingEnded) {
            revert VotingHasNotEnded();
        }
        uint256 winningVotes = 0;
        uint256 winningId = 0;
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].votes >= winningVotes) {
                winningVotes = candidates[i].votes;
                winningId = i;
            }
        }
        if (winningId == 0) revert CandidateNotFound();
        return (winningId, candidates[winningId].name, winningVotes);
    }
}