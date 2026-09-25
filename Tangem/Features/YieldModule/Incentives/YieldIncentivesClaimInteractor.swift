//
//  YieldIncentivesClaimInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

/// Owner-signed claim of the Merkl incentive rewards. Every attempt starts from fresh calldata,
/// and only one claim may be in flight until its outcome is reconciled.
actor YieldIncentivesClaimInteractor {
    @Injected(\.yieldModuleNetworkManager) private var yieldModuleNetworkManager: YieldModuleNetworkManager

    private let chainId: Int
    private let userAddress: String
    private let manager: YieldModuleManager
    private let transactionDispatcher: TransactionDispatcher
    private let tracker: YieldIncentivesClaimTracker
    private let validator = YieldClaimCalldataValidator()

    var isClaimInFlight: Bool {
        get async { await tracker.isClaimInFlight }
    }

    nonisolated var claimEventPublisher: AnyPublisher<YieldIncentivesClaimTracker.Event, Never> {
        tracker.eventPublisher
    }

    init(
        chainId: Int,
        userAddress: String,
        manager: YieldModuleManager,
        transactionDispatcher: TransactionDispatcher,
        tracker: YieldIncentivesClaimTracker
    ) {
        self.chainId = chainId
        self.userAddress = userAddress
        self.manager = manager
        self.transactionDispatcher = transactionDispatcher
        self.tracker = tracker
    }

    /// Fresh calldata → validation → owner-paid network fee; a validation failure never reaches the card.
    /// Stops at the fee: building the transaction validates the balance behind it, and the sheet has to show
    /// the fee it cannot cover rather than an error in its place.
    func prepare() async throws -> PreparedClaim {
        guard manager.blockchain.chainId == chainId else {
            throw ClaimError.moduleUnavailable
        }

        let calldata = try await yieldModuleNetworkManager.fetchClaimCalldata(chainId: chainId, userAddress: userAddress)
        let summary = try await fetchSummary()
        let validated = try validate(calldata, summary: summary)
        let fee = try await manager.claimFee(to: validated.to, data: validated.data)

        return PreparedClaim(
            calldata: calldata,
            summary: summary,
            to: validated.to,
            data: validated.data,
            fee: fee
        )
    }

    /// The earlier `prepare` result only shapes the confirmation sheet — the submitted transaction
    /// is built from calldata fetched right here, and its fresh recommendation overrides the earlier
    /// one. No automatic retries.
    func claim(confirmedFee: Decimal?, isFeeCovered: (Amount) -> Bool) async throws -> String {
        guard await tracker.beginClaim() else {
            throw ClaimError.claimAlreadyInFlight
        }

        let transaction: BSDKTransaction

        do {
            let prepared = try await prepare()

            // The sheet checked the fee it displayed; this one is the fee the card is about to sign.
            guard isFeeCovered(prepared.fee.totalFeeAmount) else {
                throw ClaimError.insufficientFee
            }

            if let confirmedFee, prepared.fee.totalFeeAmount.value > confirmedFee {
                throw ClaimError.feeIncreased
            }

            transaction = try await manager.makeClaimTransaction(to: prepared.to, data: prepared.data, fee: prepared.fee)

            guard transaction.sourceAddress.caseInsensitiveEquals(to: userAddress) else {
                throw ClaimError.moduleUnavailable
            }
        } catch {
            await tracker.releaseClaim()
            throw error
        }

        do {
            let transactionHash = try await manager.submitClaim(
                transaction: transaction,
                transactionDispatcher: transactionDispatcher
            )

            await tracker.claimSubmitted { [manager] in
                await manager.awaitPendingTransactionCleared(
                    transactionHash: transactionHash,
                    timeout: YieldIncentivesClaimTracker.reconciliationWindow
                )
            }

            return transactionHash
        } catch {
            // A declined signature is the only failure certain to have left the transaction unsent; by the time
            // anything else surfaces it is wrapped past recognition, so the rewards decide instead of the error.
            if error.isCancellationError {
                await tracker.releaseClaim()
                throw error
            }

            AppLogger.error("Yield claim submission left unresolved", error: error)
            await tracker.claimSubmissionUnresolved()

            throw ClaimError.submissionUnresolved
        }
    }

    /// Read through the shared manager so the sheet and the banner underneath cannot state different totals,
    /// and forced, because the cache window is long enough to hide rewards claimed elsewhere.
    private func fetchSummary() async throws -> YieldIncentivesRewardsSummary {
        guard let incentivesManager = manager.incentivesManager else {
            throw ClaimError.moduleUnavailable
        }

        let fetchedSummary: YieldIncentivesRewardsSummary?
        do {
            fetchedSummary = try await incentivesManager.incentives(forceRefresh: true)
        } catch where error.isCancellationError {
            throw error
        } catch {
            throw ClaimError.rewardsUnavailable
        }

        guard let summary = fetchedSummary else {
            throw ClaimError.rewardsUnavailable
        }

        return summary
    }

    private func validate(
        _ calldata: YieldClaimCalldata,
        summary: YieldIncentivesRewardsSummary
    ) throws -> YieldClaimCalldataValidator.ValidatedClaim {
        // A wallet refresh replaces the active state with `.loading`, which carries the same info in its cache.
        let state = manager.state?.state

        guard let moduleAddress = (state?.activeInfo ?? state?.cachedState?.activeInfo)?.yieldContractAddress else {
            throw ClaimError.moduleUnavailable
        }

        // Rewards reported for another module say nothing about what this one may claim.
        guard summary.moduleAddress.caseInsensitiveEquals(to: moduleAddress) else {
            throw ClaimError.rewardsUnavailable
        }

        // Calldata can still recommend a claim after the rewards behind it were taken elsewhere.
        guard !summary.claimableRewards.isEmpty else {
            throw ClaimError.rewardsUnavailable
        }

        let supportedRewardTokens = Set(
            summary.rewards
                .filter(\.isSupported)
                .map { $0.rewardTokenAddress.lowercased() }
        )

        let context = YieldClaimCalldataValidator.Context(
            chainId: chainId,
            userAddress: userAddress,
            moduleAddress: moduleAddress,
            supportedRewardTokens: supportedRewardTokens
        )

        do {
            return try validator.validate(calldata, context: context)
        } catch {
            throw ClaimError.validationFailed(error)
        }
    }
}

extension YieldIncentivesClaimInteractor {
    struct PreparedClaim {
        let calldata: YieldClaimCalldata
        let summary: YieldIncentivesRewardsSummary
        let to: String
        let data: Data
        let fee: YieldTransactionFee
    }

    enum ClaimError: Error {
        case validationFailed(YieldClaimCalldataValidator.Failure)
        case claimAlreadyInFlight
        case rewardsUnavailable
        case moduleUnavailable
        case insufficientFee
        case feeIncreased
        /// The submission may already have reached a node; the tracker decides its outcome.
        case submissionUnresolved
    }
}
