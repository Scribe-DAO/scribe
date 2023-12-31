// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ContributionDefs} from "../storage/defs/ContributionDefs.sol";
import {ProposalDefs} from "../storage/defs/ProposalDefs.sol";
import {LibCounter} from "../libs/LibCounter.sol";
import {LibEco} from "../libs/LibEco.sol";
import {LibDiamond} from "../diamond/libs/LibDiamond.sol";
import {LibStorageRetrieval} from "./LibStorageRetrieval.sol";

library LibContributionFacet {
    // Event emitted when a new contribution is created.
    event ContributionCreated(
        string indexed proposalId,
        uint256 indexed contributionId,
        address indexed contributor,
        uint256 ecoAmount,
        string cid
    );

    /**
     * @dev Create a new contribution associated with a given proposal.
     * The contribution details include a content identifier and an associated eco amount.
     * This function also updates the total eco amount of the associated proposal.
     *
     * @param _proposalId - The ID of the proposal for which the contribution is made.
     * @param _cid - Content Identifier linked with web3.storage/IPFS where contribution details are stored.
     * @param _ecoAmount - The eco token amount associated with the contribution.
     */
    function createContribution(
        string memory _proposalId,
        string memory _cid,
        uint256 _ecoAmount
    ) internal {
        // Transfer eco tokens from the sender to this contract
        require(
            LibStorageRetrieval.ecoStorage().token.transferFrom(
                msg.sender,
                address(this),
                _ecoAmount
            ),
            "LibContributionFacet.createContribution: Token transfer failed"
        );

        // Require proposal status to be OPEN
        require(
            LibStorageRetrieval
                .proposalStorage()
                .proposals[_proposalId]
                .status == ProposalDefs.ProposalStatus.OPEN,
            "LibContributionFacet.createContribution: Proposal is not OPEN"
        );

        // Generate a unique ID for the contribution using a counter
        uint256 _contributionId = LibCounter.current(
            LibStorageRetrieval
                .contributionStorage()
                .proposalContributionCounts[_proposalId]
        );

        // Store the contribution details
        LibStorageRetrieval.contributionStorage().contributions[_proposalId][
                _contributionId
            ] = ContributionDefs.Contribution(
            _proposalId,
            _contributionId,
            msg.sender,
            _ecoAmount,
            0,
            _cid
        );

        // Emit an event to signal the creation of the new contribution
        emit ContributionCreated(
            _proposalId,
            _contributionId,
            msg.sender,
            _ecoAmount,
            _cid
        );

        // Increment the counter for the next contribution ID
        LibCounter.increment(
            LibStorageRetrieval
                .contributionStorage()
                .proposalContributionCounts[_proposalId]
        );

        // Update the total eco amount associated with the proposal
        LibStorageRetrieval.proposalStorage().proposalEcoAmounts[
            _proposalId
        ] += _ecoAmount;
    }

    /**
     * @dev Retrieve the details of a specific contribution using its ID and associated proposal ID.
     *
     * @param _proposalId - The ID of the associated proposal.
     * @param _contributionId - The ID of the contribution to fetch.
     * @return Contribution details, including proposal ID, contributor, eco amount, character count, and CID.
     */
    function getContribution(
        string memory _proposalId,
        uint256 _contributionId
    ) internal view returns (ContributionDefs.Contribution memory) {
        // Return the contribution details
        return
            LibStorageRetrieval.contributionStorage().contributions[
                _proposalId
            ][_contributionId];
    }

    /**
     * @dev Update the character count of a specific contribution.
     * This function allows the contract owner to update the character count of a contribution.
     *
     * @param _proposalId - The ID of the associated proposal.
     * @param _contributionId - The ID of the contribution to update.
     * @param _characterCount - The new character count.
     */
    function updateCharacterCount(
        string memory _proposalId,
        uint256 _contributionId,
        uint256 _characterCount
    ) internal {
        // Ensure only the contract owner can update the character count
        LibDiamond.enforceIsContractOwner();

        // Update the character count in storage
        LibStorageRetrieval
        .contributionStorage()
        .contributions[_proposalId][_contributionId]
            .characterCount = _characterCount;
    }
}
