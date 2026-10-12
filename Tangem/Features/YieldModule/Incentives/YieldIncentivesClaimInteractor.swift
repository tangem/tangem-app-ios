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

actor YieldIncentivesClaimInteractor {
    @Injected(\.yieldModuleNetworkManager) private var yieldModuleNetworkManager: YieldModuleNetworkManager

    private let chainId: Int
    private let userAddress: String
    private let manager: YieldModuleManager
    private let transactionDispatcher: TransactionDispatcher
    private let tracker: YieldIncentivesClaimTracker
    private let validator = YieldClaimCalldataValidator()

    private enum Constants {
        /// Bounds how stale the Merkl proof may be, so it tracks the distributor's rollover cadence rather
        /// than the fee — the owner already agreed to the fee the sheet showed.
        static let preparationValidity: TimeInterval = 120
    }

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
            fee: fee,
            preparedAt: Date()
        )
    }

    func claim(prepared: PreparedClaim, isFeeCovered: (Amount) -> Bool) async throws -> SubmittedClaim {
        let transaction = try await makeClaimTransaction(prepared: prepared, isFeeCovered: isFeeCovered)

        do {
            let transactionHash = try await manager.submitClaim(
                transaction: transaction,
                transactionDispatcher: transactionDispatcher
            )

            await claimTransactionSubmitted(hash: transactionHash, claimedAgainst: prepared.summary)

            return SubmittedClaim(transactionHash: transactionHash, preparation: prepared)
        } catch {
            throw await claimTransactionFailed(error: error)
        }
    }

    func makeClaimTransaction(prepared: PreparedClaim, isFeeCovered: (Amount) -> Bool) async throws -> BSDKTransaction {
        guard Date().timeIntervalSince(prepared.preparedAt) < Constants.preparationValidity else {
            throw ClaimError.preparationExpired
        }

        guard await tracker.beginClaim() else {
            throw ClaimError.claimAlreadyInFlight
        }

        do {
            guard isFeeCovered(prepared.fee.totalFeeAmount) else {
                throw ClaimError.insufficientFee
            }

            let transaction = try await manager.makeClaimTransaction(to: prepared.to, data: prepared.data, fee: prepared.fee)

            guard transaction.sourceAddress.caseInsensitiveEquals(to: userAddress) else {
                throw ClaimError.moduleUnavailable
            }

            return transaction
        } catch {
            await tracker.releaseClaim()
            throw error
        }
    }

    func claimTransactionSubmitted(hash: String?, claimedAgainst summary: YieldIncentivesRewardsSummary) async {
        guard hash != nil else {
            await tracker.claimSubmissionUnresolved()
            return
        }

        await tracker.claimSubmitted { [self] in
            await isClaimReflectedByBackend(claimedAgainst: summary)
        }
    }

    private func isClaimReflectedByBackend(claimedAgainst summary: YieldIncentivesRewardsSummary) async -> Bool {
        guard let fresh = try? await fetchSummary() else {
            return false
        }

        guard fresh.isClaimRecommended else {
            return true
        }

        return summary.claimableRewards.allSatisfy { claimed in
            let remaining = fresh.claimableRewards
                .first { $0.rewardTokenAddress.caseInsensitiveEquals(to: claimed.rewardTokenAddress) }

            return (remaining?.claimableAmount ?? 0) < claimed.claimableAmount
        }
    }

    func claimTransactionFailed(error: Error) async -> Error {
        if error.isCancellationError {
            await tracker.releaseClaim()
            return error
        }

        AppLogger.error("Yield claim submission left unresolved", error: error)
        await tracker.claimSubmissionUnresolved()

        return ClaimError.submissionUnresolved(error)
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
    struct SubmittedClaim {
        let transactionHash: String
        let preparation: PreparedClaim
    }

    struct PreparedClaim {
        let calldata: YieldClaimCalldata
        let summary: YieldIncentivesRewardsSummary
        let to: String
        let data: Data
        let fee: YieldTransactionFee
        let preparedAt: Date
    }

    enum ClaimError: Error {
        case validationFailed(YieldClaimCalldataValidator.Failure)
        case claimAlreadyInFlight
        case rewardsUnavailable
        case moduleUnavailable
        case insufficientFee
        case preparationExpired
        /// The submission may already have reached a node; the tracker decides its outcome.
        case submissionUnresolved(Error)
    }
}

extension YieldIncentivesClaimInteractor.ClaimError {
    var isClaimNoLongerAvailable: Bool {
        switch self {
        case .validationFailed, .rewardsUnavailable, .moduleUnavailable:
            return true
        case .claimAlreadyInFlight, .insufficientFee, .preparationExpired, .submissionUnresolved:
            return false
        }
    }
}
