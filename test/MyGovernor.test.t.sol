// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {MyGovernor} from "../src/MyGovernor.sol";

enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }
enum VoteType { Against, For, Abstain }

contract MyGovernorTest is Test {
    GovToken govToken;
    TimeLock timelock;
    MyGovernor governor;
    SimpleStorage simpleStorage;

    address public user = makeAddr("user");
    address public admin = makeAddr("admin");

    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 300; // 5 min - delay an executor can execute a passed proposal
    uint256 public constant VOTING_DELAY = 1; // 1 block - delay from proposal until voting can start
    uint256 public constant VOTING_PERIOD = 600; // 10 min

    address[] public proposers; // empty means anybody can propose
    address[] public executors; // empty means anybody can execute

    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(user, INITIAL_SUPPLY);
        
        // user has the initial control of the timelock and will grant roles to governor and remove itself as the admin of the timelock
        vm.startPrank(user);
        govToken.delegate(user); // minting tokens is not enough. User delegates to itself to be able to vote.
        timelock = new TimeLock(MIN_DELAY, proposers, executors, user);
        governor = new MyGovernor(govToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        // only the governor can propose stuff to the timelock
        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // anybody can execute a passed proposal
        timelock.revokeRole(adminRole, user);

        simpleStorage = new SimpleStorage();
        simpleStorage.transferOwnership(address(timelock)); // timelock owns the DAO and the DAO owns the timelock, and timelock has the ultimate say on where stuff goes
        vm.stopPrank();
    }

    function testCantUpdateStoreWithoutGovernance() public {
        vm.expectRevert();
        simpleStorage.setNumber(1);
    }

    /**
     * The exact proccess how a DAO works
     */
    function testGovernanceUpdatesSimpleStorage() public {
        uint256 numberToStore = 1;
        string memory description = "Store the number 1 in the SimpleStorage contract";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("setNumber(uint256)", numberToStore);
        targets.push(address(simpleStorage));
        values.push(0); // no ETH is sent with the proposal
        calldatas.push(encodedFunctionCall);

        // 1. Propose
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // View the state of the proposal
        assert(uint256(governor.state(proposalId)) == uint256(ProposalState.Pending));
        vm.warp(block.timestamp + VOTING_DELAY + 1); // advance time to the start of the voting period
        vm.roll(block.timestamp + VOTING_DELAY + 1);
        assert(uint256(governor.state(proposalId)) == uint256(ProposalState.Active));

        // 2. Vote
        string memory reason = "Just for fun";
        uint8 voteWay = uint8(VoteType.For);
        vm.prank(user); // only "user" has GovTokens => quorum of 100%
        governor.castVoteWithReason(proposalId, voteWay, reason);

        assert(uint256(governor.state(proposalId)) == uint256(ProposalState.Active));
        vm.warp(block.timestamp + VOTING_PERIOD + 1); // advance time to the end of the voting period
        vm.roll(block.timestamp + VOTING_PERIOD + 1);
        assert(uint256(governor.state(proposalId)) == uint256(ProposalState.Succeeded));

        // 3. Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        assert(uint256(governor.state(proposalId)) == uint256(ProposalState.Queued));
        vm.warp(block.timestamp + MIN_DELAY + 1); // advance time to the start of the execution block
        vm.roll(block.timestamp + MIN_DELAY + 1);
        assert(uint256(governor.state(proposalId)) == uint256(ProposalState.Queued));

        // 4. Execute the TX
        governor.execute(targets, values, calldatas, descriptionHash);
        assert(uint256(governor.state(proposalId)) == uint256(ProposalState.Executed));

        assertEq(simpleStorage.getNumber(), numberToStore);
    }
}
