// VOTING CONTRACT
// -We are going to be writing a simple contract having the following requirements in mind:
// 1. people below the age of 18 cannot vote (underage)
// 2. only voters with valid cards can vote
// 3. the card holder must be the original cardowner
// 4. voting starts at same time
// 5. disabled and abled people can vote
// 6. both male and female can vote

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// define your contract and give it a name
contract Ballot {
    // create your state variables(think of the parties involved)- in this case, it is admin and voter
    address public admin; //stores the address of the contract administrator i.e typically the person who deployed the contract.
    uint256 public votingStart; //stores the timestamp(in seconds since Unix epoch) for when the voting is scheduled to start. also public so u can call votingStart()to see when voting starts
    bool public votingEnded; // a flag indicating whether voting has ended (true) or nor (false). initialized to false by default since bool defaults to default in solidity

    //CUSTOM ERRORS
    error UnderAge();
    error InvalidCard();
    error UnauthorizedCardHolder();
    error VotingHasEnded();
    error VotingNotStarted();
    error NotAdmin();
    error NotMale();
    error NotFemale();
    error NotDisabled();
    error NotAbled();
    error AlreadyVoted();
    error CandidateNotFound();
    error CardExpired();
    error VotingHasNotEnded();

    struct Balloter {
        address balloter;
        bool isDisabled;
        uint256 age;
        string sex;
        bool valid;
        uint256 expiry;
    }

    struct Candidate {
        uint256 id;
        string name;
        uint256 votes;
    }

    mapping(address => Balloter) public balloters; //This mapping stores the details of each voter, where the key is the voter's address and the value is a Balloter struct containing their details. THis allows us to easily access and manage voter information by their address. This is a public mapping, so you can call balloters() to see the details of each voter. This is a mapping which is like a key-value data store. The key is the ethereum address of the voter, and the value is a Balloter struct containing the voter's details such as their age, disability, Id, status, and expiry date of their voting card. This allows us to easily access and manage voter information by their address. This is a public mapping, so you can call balloters() to see the details of each voter.
    mapping(uint256 => Candidate) public candidates; //This stores information about each candidate, indexed by an ID E.G 1,2, 3,4...This mapping stores the candidates, where the key is the candidate's ID and the value is a Candidate struct containing their details. This allows us to easily access and manage candidate information by their ID. This is a public mapping, so you can call candidates() to see the details of each candidate.
    mapping(address => bool) public hasVoted; //This mapping keeps track of whether a voter has already voted. The key is the voter's address, and the value is a boolean indicating if they have voted (true) or not (false). This allows us to easily check if a voter has already cast their vote.
    uint256 public candidateCount; //This simply keeps track of how many candidates have been added so far. It is public so u can check the number of candidates using -candidateCount( returns the number of registered candidates). it is usually incremented when a new candidate is added: candidateCount++; candidates[Candidate] = candidate(2). candidateCOunt is needed because candidates are added by the admin one at a time. Each candidate is stored in the earlier mapping but since mapping don't store length or keys, we need candidateCount to 1. keep track of how many we have added and iterate through them when needed
    uint256 public balloterCount;

    event CandidateAdded (uint256 indexed id, string name); //This event is emitted when a new candidate is added. It includes a message, the candidate's ID, and their name. Events are used to log information on the blockchain that can be accessed later by external applications or users. This allows us to notify listeners (like front-end applications) when a new candidate is added to the election.
    event BalloterRegistered(address _balloter, uint _age, bool isDisabled, string sex);
    event VoteCasted(address _balloter, uint256 indexed candidateCount);
    event VotingEnded(uint256 indexed timestamp);




    //CONSTRUCTOR -A constructor is a special function that runs only once when the contract is deployed
    constructor(
        uint256 _votingStart //votingStart is the only parameter passed in the constructor because that is the only piece of information the contract designer decided to let the deployer(the one who deploys the contract, in our case the admin) customize at deployment time. THe voting time might vary, so we allow custom input(3 design reasoning --- flexibility, security and simplicity, defaults)
    ) {
        admin = msg.sender; //the address that deployed the contract
        votingStart = _votingStart; //this parameter is passed to the constructor to set the votingStart time
    }

    // CUSTOM MODIFIERS - reusable chunks of code that help u enforce rules before running the actual logic of functions
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin(); //restricts access to certain functions(admin functions), allowing only the admin to call them. now, checks is msg.sender is not the admin and revert NotAdmin() custom error. This saves gas compared to required.
        _; //this is where the function body will be executed // This is a placeholder, when the modifier is used in a function, this placeholder is replaced by the body of thet function
    }

    modifier votingOpen() {
        if (block.timestamp < votingStart) revert VotingNotStarted(); // both modifiers ensure readability, reusability, security by abstracting repetitive checks out of function
        if (votingEnded) revert VotingHasEnded();
        _;
    }

    // FUNCTION TO ADD CANDIDATE
    function addCandidate(string memory _name) public onlyAdmin {
        candidateCount++; //increment the candidate count
        candidates[candidateCount] = Candidate(candidateCount, _name, 0); //add the new candidate to the candidates mapping with their ID, name and initial votes of 0. // The addCandidate function allows the admin to add a new candidate to the election. It takes the candidate's name as a parameter, increments the candidate count, and adds the new candidate to the candidates mapping with their ID, name, and initial votes of 0. The onlyAdmin modifier ensures that only the admin can call this function.
        
        emit CandidateAdded(candidateCount, _name); //emit an event to notify that a candidate has been added
    }

function registerBalloter(address _balloter, bool isDisabled, uint256 age, string memory sex, bool valid, uint256 expiry) public onlyAdmin {
    if (balloters[_balloter].valid) {
        revert InvalidCard();
    }
    
    if (age < 18) {
        revert UnderAge();
    } //check if the voter is underage

    if (expiry < block.timestamp) {
        revert CardExpired();
    }
    balloters[_balloter] = Balloter({
        balloter: _balloter,
        isDisabled: isDisabled,
        age: age,
        sex: sex,
        valid: valid,
        expiry: expiry
    });
    balloterCount++;
    
emit BalloterRegistered(_balloter, age, true, sex);
}

function castVote(address _balloter, uint256 candidateId) public votingOpen {
    Balloter memory balloter = balloters[_balloter];
    if (!balloter.valid) revert InvalidCard();
    if (balloter.balloter != _balloter) revert UnauthorizedCardHolder();
    if (balloter.expiry <= block.timestamp) revert InvalidCard();
    if (hasVoted[_balloter]) revert AlreadyVoted();
    if (candidateId == 0 || candidateId > candidateCount) revert CandidateNotFound();

    candidates[candidateId].votes++;
    hasVoted[_balloter] = true;
    emit VoteCasted(_balloter, candidateId);
}

function endVoting() public onlyAdmin {
    if (votingEnded) revert VotingHasEnded();
    if (block.timestamp < votingStart) revert VotingNotStarted();
    votingEnded = true;
    emit VotingEnded(block.timestamp);
}


// Function to get the current results (view-only) --- it is a view once function because it does not modify the state of the contract, it only reads data. it is designed to return the current results of the election, including the candidates and their vote counts. This function can be called by anyone to see the current state of the election. it is designed to return the full list of candidates along with their vote counts. Returns the entire array of Candidate structs(each with ID, NAME, VOTE COUNT)
function getResults() public view returns(Candidate[] memory) {// it declares a public function called getResults. it returns a dynamic array of structs(in memory), it does not change the state hence marked view
    Candidate[] memory result = new Candidate[] (candidateCount); // a new in-memory array named result to hold the Candidate objects and candidateCount is the size of this array, it allocates enough enough space for all registered candidates.
    for (uint256 i = 1; i <= candidateCount; i++){ //iterates from candidate ID 1 up to the total number of candidates and then,
        if(candidates[i].id != 0){  //checks that the candidate's ID is not 0. THis is a safety check incase the candidate was improperly initialized(though my logic already avoids that).
            result[i - 1] = candidates[i]; //fills the result array with candidate data, uses i-1 to correctly position items in the array starting from index 0
        }
    }
    return result;
}

function getWinner() public view returns(uint candidateId, string memory name, uint256 votes) {//The function returns the winning candidate's ID, name, and number of votes — but only after voting has ended. it returns 3 values candidateId, name of thewinner and number of votes the winner received
 if(!votingEnded) {
    revert VotingHasNotEnded(); //security check: only allow access after voting ends
    }

    uint256 winningVotes = 0; // two temporary variables --winningVotes, winningId
    uint256 winningId = 0;

    for(uint256 i = 1; i <= candidateCount; i++){ //loop or iterate through all candidates starting from 1
        if(candidates[i].id != 0 && candidates[i].votes > winningVotes) {
            winningVotes = candidates[i].votes;
            winningId = i;
        }
    }
if (winningId == 0) revert CandidateNotFound();
    return (winningId, candidates[winningId].name, winningVotes);
}

}


