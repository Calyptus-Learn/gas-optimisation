// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegation.
contract Ballot {
    // Errors
    // @optimization using custom errors
    /// Only chairperson can give right to vote
    error OnlyChairPerson();
    /// The voter already voted.
    error AlreadyVoted();
    /// Voter already has weighage
    error WeighageNotZero();
    /// You have no right to vote
    error CantVote();
    /// You have already voted
    error AlreadyVoter();
    /// Self delegation is not allowed
    error SelfDelegationNotAllowed();
    /// Found loop in delegation
    error LoopInDelegation();
    /// Voters cannot delegate to accounts that cannot vote.
    error NoDelegationToNonVoter();

    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    // @optimization using packing of storage variables
    struct Voter {
        uint32 weight; // weight is accumulated by delegation
        uint32 vote; // index of the voted proposal
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
    }

    // This is a type for a single proposal.
    // @optimization using packing of storage variables
    // @optimization using bytes32 instead of string
    struct Proposal {
        bytes32 name; // short name (up to 32 bytes)
        uint32 voteCount; // number of accumulated votes
    }

    address public chairperson;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    // @optimization using bytes32 instead of string
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint i = 0; i < proposalNames.length; ) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
            // @optimization using unchecked for increment
            unchecked {
                i++;
            }
        }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) external {
        if (msg.sender != chairperson) revert OnlyChairPerson();
        if (voters[voter].voted) revert AlreadyVoted();
        if (voters[voter].weight != 0) revert WeighageNotZero();
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) external {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        if (sender.weight == 0) revert CantVote();
        if (sender.voted) revert AlreadyVoter();
        if (to == msg.sender) revert SelfDelegationNotAllowed();

        // Forward the delegation as long as
        // `to` also delegated.
        // In general, such loops are very dangerous,
        // because if they run too long, they might
        // need more gas than is available in a block.
        // In this case, the delegation will not be executed,
        // but in other situations, such loops might
        // cause a contract to get "stuck" completely.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            if (to == msg.sender) revert LoopInDelegation();
        }

        Voter storage delegate_ = voters[to];

        // Voters cannot delegate to accounts that cannot vote.
        if (delegate_.weight < 1) revert NoDelegationToNonVoter();

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender]`.
        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint32 proposal) external {
        Voter storage sender = voters[msg.sender];
        if (sender.weight == 0) revert CantVote();
        if (sender.voted) revert AlreadyVoted();
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        uint length = proposals.length;
        for (uint p = 0; p < length; ) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
            // @optimization using unchecked for increment
            unchecked {
                p++;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
