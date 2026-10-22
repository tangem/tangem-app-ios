//
//  StakeKitStakingManagerPendingActionsTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import os
import Testing
@testable import TangemStaking

struct StakeKitStakingManagerPendingActionsTests {
    private let validatorAddress = "BbM5kJgrwEj3tYFfBPnjcARB54yRXPZDz4NR4gYHNfPt"
    private let tokenItem = StakingTokenItem(network: .solana, name: "Solana", decimals: 9, symbol: "SOL")
    private let unstakeAmount = Decimal(string: "1.0118")!

    @Test
    func partialUnstakeAlreadyReflectedInBalancesIsNotSubtractedAgain() async throws {
        let apiProvider = StubStakeKitAPIProvider(balances: [balance(amount: "2.052775655", type: .active)])
        let manager = makeManager(apiProvider: apiProvider)

        await manager.updateState(loadActions: true, startUpdateDate: .distantPast)
        _ = try await manager.transaction(action: unstakeAction)

        apiProvider.respond(
            balances: [
                balance(amount: "1.01346624", type: .unbonding(date: Date(timeIntervalSince1970: 1_000))),
                balance(amount: "1.040975655", type: .active),
            ],
            actions: [processingUnstake]
        )
        await manager.updateState(loadActions: true, startUpdateDate: .distantPast)

        #expect(rows(of: manager) == [
            Row(amount: "1.01346624", isUnbonding: true, inProgress: false),
            Row(amount: "1.040975655", isUnbonding: false, inProgress: false),
        ])
    }

    @Test
    func partialUnstakeNotYetReflectedInBalancesIsShownInProgress() async throws {
        let apiProvider = StubStakeKitAPIProvider(balances: [balance(amount: "2.052775655", type: .active)])
        let manager = makeManager(apiProvider: apiProvider)

        await manager.updateState(loadActions: true, startUpdateDate: .distantPast)
        _ = try await manager.transaction(action: unstakeAction)

        apiProvider.respond(balances: [balance(amount: "2.052775655", type: .active)], actions: [processingUnstake])
        await manager.updateState(loadActions: true, startUpdateDate: .distantPast)

        #expect(rows(of: manager) == [
            Row(amount: "1.040975655", isUnbonding: false, inProgress: false),
            Row(amount: "1.0118", isUnbonding: false, inProgress: true),
        ])
    }

    @Test
    func firstStakeAlreadyReflectedInBalancesIsNotDuplicated() async throws {
        let apiProvider = StubStakeKitAPIProvider(balances: [])
        let manager = makeManager(apiProvider: apiProvider)
        let stakeAction = StakingAction(amount: 1, targetType: .target(target), type: .stake)

        await manager.updateState(loadActions: true, startUpdateDate: .distantPast)
        _ = try await manager.transaction(action: stakeAction)

        apiProvider.respond(
            balances: [balance(amount: "1", type: .warmup)],
            actions: [pendingAction(type: .stake, amount: 1)]
        )
        await manager.updateState(loadActions: true, startUpdateDate: .distantPast)

        #expect(rows(of: manager) == [Row(amount: "1", isUnbonding: false, inProgress: false)])
    }

    @Test
    func failedTransactionBuildDoesNotHideLaterServerAction() async throws {
        let apiProvider = StubStakeKitAPIProvider(balances: [balance(amount: "2.052775655", type: .active)])
        let manager = makeManager(apiProvider: apiProvider)

        await manager.updateState(loadActions: true, startUpdateDate: .distantPast)
        apiProvider.failTransactionBuild()
        await #expect(throws: (any Error).self) {
            try await manager.transaction(action: unstakeAction)
        }

        apiProvider.respond(balances: [balance(amount: "2.06", type: .active)], actions: [processingUnstake])
        await manager.updateState(loadActions: true, startUpdateDate: .distantPast)

        #expect(rows(of: manager) == [
            Row(amount: "1.0482", isUnbonding: false, inProgress: false),
            Row(amount: "1.0118", isUnbonding: false, inProgress: true),
        ])
    }

    // MARK: - Fixtures

    private var target: StakingTargetInfo {
        StakingTargetInfo(
            address: validatorAddress,
            name: "Solana Validator",
            preferred: true,
            partner: false,
            image: nil,
            rewardType: .apy,
            rewardRate: 0.0535,
            status: .active,
            allowsPartialUnstake: true
        )
    }

    private var unstakeAction: StakingAction {
        StakingAction(amount: unstakeAmount, targetType: .target(target), type: .unstake)
    }

    private var processingUnstake: PendingAction {
        pendingAction(type: .unstake, amount: unstakeAmount)
    }

    private func pendingAction(type: StakingPendingActionInfo.ActionType, amount: Decimal) -> PendingAction {
        PendingAction(
            id: "server-id",
            status: .processing,
            amount: amount,
            type: type,
            currentStepIndex: 0,
            transactions: [],
            targetAddress: validatorAddress
        )
    }

    private func balance(amount: String, type: StakingBalanceType) -> StakingBalanceInfo {
        StakingBalanceInfo(
            item: tokenItem,
            amount: Decimal(string: amount)!,
            balanceType: type,
            targetAddress: validatorAddress,
            actions: []
        )
    }

    private func makeManager(apiProvider: StubStakeKitAPIProvider) -> StakeKitStakingManager {
        StakeKitStakingManager(
            integrationId: "solana-sol-native-multivalidator-staking",
            wallet: StakingWallet(item: tokenItem, address: "wallet-address", publicKey: Data()),
            apiProvider: apiProvider,
            yieldInfoProvider: StubYieldInfoProvider(yield: yield),
            stateRepository: StubStateRepository(),
            analyticsLogger: StubAnalyticsLogger()
        )
    }

    private var yield: StakingYieldInfo {
        StakingYieldInfo(
            id: "solana-sol-native-multivalidator-staking",
            isAvailable: true,
            rewardType: .apy,
            rewardRateValues: .single(0.0535),
            enterMinimumRequirement: 0,
            exitMinimumRequirement: 0,
            targets: [target],
            preferredTargets: [target],
            item: tokenItem,
            unbondingPeriod: .days(3),
            warmupPeriod: .days(3),
            rewardClaimingType: .auto,
            rewardScheduleType: .days(min: 2, max: 3),
            maximumStakeAmount: nil
        )
    }

    private func rows(of manager: StakeKitStakingManager) -> [Row] {
        guard case .staked(let staked) = manager.state else {
            return []
        }

        return staked.balances.map { balance in
            let isUnbonding = switch balance.balanceType {
            case .unbonding: true
            default: false
            }

            return Row(amount: "\(balance.amount)", isUnbonding: isUnbonding, inProgress: balance.inProgress)
        }
    }
}

private struct Row: Equatable {
    let amount: String
    let isUnbonding: Bool
    let inProgress: Bool
}

private struct StubError: Error {}

private final class StubStakeKitAPIProvider: StakeKitAPIProvider {
    private struct Responses {
        var balances: [StakingBalanceInfo]
        var actions: [PendingAction]
        var failsTransactionBuild = false
    }

    private let responses: OSAllocatedUnfairLock<Responses>

    init(balances: [StakingBalanceInfo]) {
        responses = OSAllocatedUnfairLock(initialState: Responses(balances: balances, actions: []))
    }

    func respond(balances: [StakingBalanceInfo], actions: [PendingAction]) {
        responses.withLock {
            $0.balances = balances
            $0.actions = actions
        }
    }

    func failTransactionBuild() {
        responses.withLock { $0.failsTransactionBuild = true }
    }

    private func buildStep<T>(_ result: T) throws -> T {
        if responses.withLock({ $0.failsTransactionBuild }) {
            throw StubError()
        }

        return result
    }

    func balances(wallet: StakingWallet, integrationId: String) async throws -> [StakingBalanceInfo] {
        responses.withLock { $0.balances }
    }

    func actions(wallet: StakingWallet) async throws -> [PendingAction] {
        responses.withLock { $0.actions }
    }

    func enabledYields() async throws -> [StakingYieldInfo] { throw StubError() }
    func yield(integrationId: String) async throws -> StakingYieldFetchResult { throw StubError() }
    func estimateStakeFee(request: ActionGenericRequest) async throws -> Decimal { throw StubError() }
    func estimateUnstakeFee(request: ActionGenericRequest) async throws -> Decimal { throw StubError() }
    func estimatePendingFee(request: PendingActionRequest) async throws -> Decimal { throw StubError() }
    func enterAction(request: ActionGenericRequest) async throws -> EnterAction {
        try buildStep(
            EnterAction(id: "enter-id", status: .created, amount: request.amount, currentStepIndex: 0, transactions: [actionTransaction])
        )
    }

    func exitAction(request: ActionGenericRequest) async throws -> ExitAction {
        try buildStep(
            ExitAction(id: "exit-id", status: .created, amount: request.amount, currentStepIndex: 0, transactions: [actionTransaction])
        )
    }

    func patchTransaction(id: String) async throws -> StakingTransactionInfo {
        try buildStep(StakingTransactionInfo(network: "solana", unsignedTransactionData: .raw("unsigned"), fee: 0.000025))
    }

    private var actionTransaction: ActionTransaction {
        ActionTransaction(id: "transaction-id", stepIndex: 0)
    }

    func pendingAction(request: PendingActionRequest) async throws -> PendingAction { throw StubError() }
    func transaction(id: String) async throws -> StakingTransactionInfo { throw StubError() }
    func submitTransaction(hash: String, signedTransaction: String) async throws { throw StubError() }
    func submitHash(hash: String, transactionId: String) async throws { throw StubError() }
}

private struct StubYieldInfoProvider: StakingYieldInfoProvider {
    let yield: StakingYieldInfo

    var stakingTargets: AsyncStream<[StakingTargetSummary]> {
        AsyncStream { $0.finish() }
    }

    func yieldInfo(for integrationId: String) async throws -> StakingYieldInfo {
        yield
    }
}

private struct StubStateRepository: StakingManagerStateRepository {
    func storeState(_ state: StakingManagerState) {}
    func state() -> CachedStakingManagerState? { nil }
    func clearState() {}
}

private struct StubAnalyticsLogger: StakingAnalyticsLogger {
    func logError(_ error: any Error, currencySymbol: String) {}
}
