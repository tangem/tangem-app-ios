//
//  YieldIncentivesClaimInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
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
    private let validator = YieldClaimCalldataValidator()

    private(set) var isClaimInFlight = false

    init(
        chainId: Int,
        userAddress: String,
        manager: YieldModuleManager,
        transactionDispatcher: TransactionDispatcher
    ) {
        self.chainId = chainId
        self.userAddress = userAddress
        self.manager = manager
        self.transactionDispatcher = transactionDispatcher
    }

    /// Fresh calldata → validation → owner-paid network fee; a validation failure never reaches the card.
    func prepare() async throws -> PreparedClaim {
        guard manager.blockchain.chainId == chainId else {
            throw ClaimError.moduleUnavailable
        }

        let calldata = try await yieldModuleNetworkManager.fetchClaimCalldata(chainId: chainId, userAddress: userAddress)
        let validated = try await validate(calldata)
        let fee = try await manager.claimFee(to: validated.to, data: validated.data)
        let transaction = try await manager.makeClaimTransaction(to: validated.to, data: validated.data, fee: fee)

        guard transaction.sourceAddress.caseInsensitiveEquals(to: userAddress) else {
            throw ClaimError.moduleUnavailable
        }

        return PreparedClaim(calldata: calldata, to: validated.to, data: validated.data, fee: fee, transaction: transaction)
    }

    /// The earlier `prepare` result only shapes the confirmation sheet — the submitted transaction
    /// is built from calldata fetched right here, and its fresh recommendation overrides the earlier
    /// one. No automatic retries.
    func claim() async throws -> String {
        guard !isClaimInFlight else {
            throw ClaimError.claimAlreadyInFlight
        }

        isClaimInFlight = true

        let prepared: PreparedClaim

        do {
            prepared = try await prepare()
        } catch {
            isClaimInFlight = false
            throw error
        }

        do {
            return try await manager.submitClaim(
                transaction: prepared.transaction,
                transactionDispatcher: transactionDispatcher
            )
        } catch {
            // Only a declined signature is certain to have reached no node; any later failure may already be
            // broadcast, so the guard holds until the outcome is reconciled.
            if error.isCancellationError {
                isClaimInFlight = false
            }

            throw error
        }
    }

    /// Releases the single-flight guard once the submitted claim is reconciled — confirmed,
    /// definitively failed, or resolved through a rewards refresh.
    func finishClaim() {
        isClaimInFlight = false
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

    private func validate(_ calldata: YieldClaimCalldata) async throws -> YieldClaimCalldataValidator.ValidatedClaim {
        let summary = try await fetchSummary()

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
        let to: String
        let data: Data
        let fee: YieldTransactionFee
        let transaction: BSDKTransaction
    }

    enum ClaimError: Error {
        case validationFailed(YieldClaimCalldataValidator.Failure)
        case claimAlreadyInFlight
        case rewardsUnavailable
        case moduleUnavailable
    }
}
