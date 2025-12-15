//
//  StakeKitStakingManager.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

final class StakeKitStakingManager {
    private let integrationId: String
    private let wallet: StakingWallet
    private let provider: StakeKitAPIProvider
    private let stateRepository: StakingManagerStateRepository
    private let analyticsLogger: StakingAnalyticsLogger

    private(set) var balances: [StakingBalance]?

    // MARK: Private

    private let _state: CurrentValueSubject<StakingManagerState, Never>
    private var canStakeMore: Bool {
        switch wallet.item.network {
        case .solana, .cosmos, .tron, .ethereum, .bsc, .ton: true
        default: false
        }
    }

    init(
        integrationId: String,
        wallet: StakingWallet,
        provider: StakeKitAPIProvider,
        stateRepository: StakingManagerStateRepository,
        analyticsLogger: StakingAnalyticsLogger
    ) {
        self.integrationId = integrationId
        self.wallet = wallet
        self.provider = provider
        self.stateRepository = stateRepository
        self.analyticsLogger = analyticsLogger

        _state = CurrentValueSubject<StakingManagerState, Never>(.loading(cached: stateRepository.state()))
    }
}

// MARK: - StakingManager

extension StakeKitStakingManager: StakingManager {
    var state: StakingManagerState {
        _state.value
    }

    var statePublisher: AnyPublisher<StakingManagerState, Never> {
        _state.eraseToAnyPublisher()
    }

    var allowanceAddress: String? {
        switch (wallet.item.network, wallet.item.contractAddress) {
        case (.ethereum, StakingConstants.polygonContractAddress):
            return "0x5e3ef299fddf15eaa0432e6e66473ace8c13d908"
        default:
            return nil
        }
    }

    func updateState(loadActions: Bool) async {
        await updateState(loadActions: loadActions, startUpdateDate: nil)
    }

    func updateState(loadActions: Bool, startUpdateDate: Date? = nil) async {
        await updateState(.loading(cached: stateRepository.state()))
        do {
            async let balances = provider.balances(wallet: wallet, integrationId: integrationId)
            async let yield = provider.yield(integrationId: integrationId)
            async let actions = loadActions ? provider.actions(wallet: wallet) : []

            let (loadedBalances, loadedYield, loadedActions) = try await (balances, yield, actions)
            await updateState(state(balances: loadedBalances, yield: loadedYield, actions: loadedActions))

            let effectiveStartUpdateDate = startUpdateDate ?? Date()

            if loadActions, !loadedActions.isEmpty,
               Date().timeIntervalSince(effectiveStartUpdateDate) < Constants.statusUpdateTimeout {
                try await Task.sleep(for: .seconds(Constants.statusUpdateInterval)) // Refresh pending actions status until empty
                await updateState(loadActions: true, startUpdateDate: effectiveStartUpdateDate)
            }
        } catch is CancellationError {
            // Ignored intentionally
            return
        } catch {
            analyticsLogger.logError(error, currencySymbol: wallet.item.symbol)
            StakingLogger.error(self, error: error)
            await updateState(.loadingError(error.localizedDescription, cached: stateRepository.state()))
        }
    }

    func estimateFee(action: StakingAction) async throws -> Decimal {
        switch (state, action.type) {
        case (.loading, _):
            try await waitForLoadingCompletion()
            return try await estimateFee(action: action)
        case (.availableToStake, .stake), (.staked, .stake):
            return try await execute(
                try await provider.estimateStakeFee(
                    request: mapToActionGenericRequest(action: action)
                )
            )
        case (.staked, .unstake):
            return try await execute(
                try await provider.estimateUnstakeFee(
                    request: mapToActionGenericRequest(action: action)
                )
            )
        case (.staked, .pending(let type)):
            return try await getPendingEstimateFee(
                request: mapToActionGenericRequest(action: action),
                type: type
            )
        default:
            StakingLogger.info(self, "Invalid staking manager state: \(state), for action: \(action)")
            throw StakingManagerError.stakingManagerStateNotSupportEstimateFeeAction(action: action, state: state)
        }
    }

    func transaction(action: StakingAction) async throws -> StakingTransactionAction {
        switch (state, action.type) {
        case (.loading, _):
            try await waitForLoadingCompletion()
            return try await transaction(action: action)
        case (.availableToStake, .stake), (.staked, .stake):
            return try await getStakeTransactionInfo(
                request: mapToActionGenericRequest(action: action)
            )
        case (.staked, .unstake):
            return try await getUnstakeTransactionInfo(
                request: mapToActionGenericRequest(action: action)
            )
        case (.staked, .pending(let type)):
            return try await getPendingTransactionInfo(
                request: mapToActionGenericRequest(action: action),
                type: type
            )
        default:
            throw StakingManagerError.stakingManagerStateNotSupportTransactionAction(action: action, state: state)
        }
    }

    func transactionDidSent(action: StakingAction) {
        runTask(in: self) {
            await $0.updateState(loadActions: true)
        }
    }
}

// MARK: - Private

private extension StakeKitStakingManager {
    @MainActor
    func updateState(_ state: StakingManagerState) {
        StakingLogger.info(self, "Update state to \(state)")
        stateRepository.storeState(state)
        _state.send(state)
        updateBalances(state)
    }

    func updateBalances(_ state: StakingManagerState) {
        switch state {
        case .loading:
            break
        case .staked(let stakeInfo):
            balances = stakeInfo.balances
        case .availableToStake,
             .loadingError,
             .notEnabled,
             .temporaryUnavailable:
            balances = nil
        }
    }

    func state(balances: [StakingBalanceInfo], yield: StakingYieldInfo, actions: [PendingAction]?) -> StakingManagerState {
        guard yield.isAvailable else {
            return .temporaryUnavailable(yield)
        }

        let stakingBalances = balances.map { balance in
            mapToStakingBalance(balance: balance, yield: yield)
        }

        let pendingActionsHandler = StakingPendingActionsHandlerProvider().makeStakingPendingActionsHandler(
            network: yield.item.network
        )

        let mergedBalances = pendingActionsHandler.mergeBalancesAndPendingActions(
            balances: stakingBalances,
            actions: actions,
            yield: yield
        )

        guard !mergedBalances.isEmpty else {
            return .availableToStake(yield)
        }

        return .staked(.init(balances: mergedBalances, yieldInfo: yield, canStakeMore: canStakeMore))
    }

    func getStakeTransactionInfo(request: ActionGenericRequest) async throws -> StakingTransactionAction {
        let action = try await execute(try await provider.enterAction(request: request))

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await action.transactions.asyncMap { transaction in
            try await execute(try await provider.patchTransaction(id: transaction.id))
        }

        return mapToStakingTransactionAction(
            actionID: action.id,
            amount: action.amount,
            target: request.target,
            transactions: transactions
        )
    }

    func getUnstakeTransactionInfo(request: ActionGenericRequest) async throws -> StakingTransactionAction {
        let action = try await execute(try await provider.exitAction(request: request))

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await withThrowingTaskGroup(of: StakingTransactionInfo.self) { group in
            action.transactions.forEach { transaction in
                group.addTask {
                    try Task.checkCancellation()
                    return try await self.execute(try await self.provider.patchTransaction(id: transaction.id))
                }
            }

            var transactions = [StakingTransactionInfo]()
            for try await transaction in group {
                transactions.append(transaction)
            }

            return transactions
        }

        return mapToStakingTransactionAction(
            actionID: action.id,
            amount: action.amount,
            target: request.target,
            transactions: transactions.sorted {
                guard let firstMetadata = $0.metadata as? StakeKitTransactionMetadata,
                      let secondMetadata = $1.metadata as? StakeKitTransactionMetadata else {
                    return false
                }
                return firstMetadata.stepIndex > secondMetadata.stepIndex
            }
        )
    }

    func getPendingTransactionInfo(request: ActionGenericRequest, type: StakingAction.PendingActionType) async throws -> StakingTransactionAction {
        switch type {
        case .claimRewards(let passthrough),
             .restakeRewards(let passthrough),
             .voteLocked(let passthrough),
             .unlockLocked(let passthrough),
             .restake(let passthrough),
             .stake(let passthrough):
            let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
            let action = try await getPendingTransactionAction(request: request)
            return action
        case .withdraw(let passthroughs), .claimUnstaked(let passthroughs):
            let actions = try await withThrowingTaskGroup(of: StakingTransactionAction.self) { group in
                for passthrough in passthroughs {
                    let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
                    group.addTask {
                        try await self.getPendingTransactionAction(request: request)
                    }
                }

                var actions = [StakingTransactionAction]()
                for try await action in group {
                    actions.append(action)
                }
                return actions
            }

            return mapToStakingTransactionAction(
                amount: request.amount,
                target: request.target,
                transactions: actions.flatMap { $0.transactions }
            )
        }
    }

    func getPendingTransactionAction(request: PendingActionRequest) async throws -> StakingTransactionAction {
        let action = try await execute(try await provider.pendingAction(request: request))

        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: Constants.delay)

        let transactions = try await action.transactions.asyncMap { transaction in
            try await execute(try await provider.patchTransaction(id: transaction.id))
        }

        return mapToStakingTransactionAction(
            actionID: action.id,
            amount: action.amount,
            target: request.request.target,
            transactions: transactions
        )
    }

    func getPendingEstimateFee(request: ActionGenericRequest, type: StakingAction.PendingActionType) async throws -> Decimal {
        switch type {
        case .claimRewards(let passthrough),
             .restakeRewards(let passthrough),
             .voteLocked(let passthrough),
             .unlockLocked(let passthrough),
             .restake(let passthrough),
             .stake(let passthrough):
            let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
            return try await execute(try await provider.estimatePendingFee(request: request))
        case .withdraw(let passthroughs), .claimUnstaked(let passthroughs):
            let fees = try await passthroughs.asyncMap { passthrough in
                let request = PendingActionRequest(request: request, passthrough: passthrough, type: type)
                return try await execute(try await provider.estimatePendingFee(request: request))
            }

            return fees.reduce(0, +)
        }
    }

    private func execute<T>(_ request: @autoclosure () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch {
            analyticsLogger.logError(
                error,
                currencySymbol: wallet.item.symbol
            )
            throw error
        }
    }
}

// MARK: - Helping

private extension StakeKitStakingManager {
    func mapToActionGenericRequest(action: StakingAction) -> ActionGenericRequest {
        .init(
            amount: action.amount,
            address: wallet.address,
            additionalAddresses: getAdditionalAddresses(),
            token: wallet.item,
            target: action.targetInfo?.address,
            integrationId: integrationId,
            tronResource: getTronResource()
        )
    }

    func mapToStakingBalance(
        action: PendingAction,
        yield: StakingYieldInfo,
        balanceType: StakingBalanceType
    ) -> StakingBalance {
        let targetType: StakingTargetType = {
            guard let address = action.targetAddress,
                  let target = yield.targets.first(where: { $0.address == address }) else {
                return .empty
            }

            return .target(target)
        }()

        return StakingBalance(
            item: yield.item,
            amount: action.amount,
            balanceType: balanceType,
            targetType: targetType,
            inProgress: true,
            actions: []
        )
    }

    // MARK: - Staking transaction action

    func mapToStakingTransactionAction(
        actionID: String? = nil,
        amount: Decimal,
        target: String?,
        transactions: [StakingTransactionInfo]
    ) -> StakingTransactionAction {
        StakingTransactionAction(
            id: actionID,
            amount: amount,
            target: target,
            transactions: transactions
        )
    }
}

// MARK: - Blockchain specific

private extension StakeKitStakingManager {
    func getAdditionalAddresses() -> AdditionalAddresses? {
        switch wallet.item.network {
        case .cosmos, .kava, .near:
            guard let compressedPublicKey = try? Secp256k1Key(with: wallet.publicKey).compress() else {
                return nil
            }

            return AdditionalAddresses(cosmosPubKey: compressedPublicKey.base64EncodedString())
        default:
            return nil
        }
    }

    func getTronResource() -> String? {
        switch wallet.item.network {
        case .tron:
            return StakeKitDTO.Actions.ActionArgs.TronResource.energy.rawValue
        default:
            return nil
        }
    }
}

// MARK: - Log

extension StakeKitStakingManager: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: ["item": wallet.item])
    }
}

private extension StakeKitStakingManager {
    enum Constants {
        static let delay: UInt64 = 1 * NSEC_PER_SEC
        static let statusUpdateInterval: TimeInterval = 10
        static let statusUpdateTimeout: TimeInterval = 180 // 3 minutes should be enough to process staking actions
    }
}

public enum StakingManagerError: LocalizedError {
    case stakingManagerStateNotSupportTransactionAction(action: StakingAction, state: StakingManagerState)
    case stakingManagerStateNotSupportEstimateFeeAction(action: StakingAction, state: StakingManagerState)
    case stakingManagerIsLoading

    public var errorDescription: String? {
        switch self {
        case .stakingManagerStateNotSupportTransactionAction(let action, let state):
            "StakingManagerNotSupportTransactionAction \(action.type) state \(state.description)"
        case .stakingManagerStateNotSupportEstimateFeeAction(let action, let state):
            "StakingManagerNotSupportTransactionAction \(action.type) state \(state.description)"
        case .stakingManagerIsLoading:
            "StakingManagerIsLoading"
        }
    }
}
