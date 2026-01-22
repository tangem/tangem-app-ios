//
//  P2PStakingManager.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class P2PStakingManager {
    private let wallet: StakingWallet
    private let provider: P2PAPIProvider
    private let analyticsLogger: StakingAnalyticsLogger

    private let _state = CurrentValueSubject<StakingManagerState, Never>(.loading)

    init(wallet: StakingWallet, provider: P2PAPIProvider, analyticsLogger: StakingAnalyticsLogger) {
        self.wallet = wallet
        self.provider = provider
        self.analyticsLogger = analyticsLogger
    }
}

// MARK: - StakingManager

extension P2PStakingManager: StakingManager {
    func updateState(loadActions: Bool) async {
        _state.send(.loading)

        let yield = try? await provider.yield()

        guard let yield, !yield.validators.isEmpty else {
            _state.send(.notEnabled)
            return
        }

        let balances = try? await provider.balances(wallet: wallet, vaults: yield.validators.map(\.address))
        let state = state(balances: balances, yield: yield)
        _state.send(state)
    }

    var statePublisher: AnyPublisher<StakingManagerState, Never> {
        _state.eraseToAnyPublisher()
    }

    var updateWalletBalancesPublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    var state: StakingManagerState {
        _state.value
    }

    var balances: [StakingBalance]? {
        []
    }

    var allowanceAddress: String? {
        nil
    }

    func estimateFee(action: StakingAction) async throws -> Decimal {
        fatalError()
    }

    func transaction(action: StakingAction) async throws -> StakingTransactionAction {
        fatalError()
    }

    func transactionDetails(id: String) async throws -> StakingTransactionInfo {
        fatalError()
    }

    func transactionDidSent(action: StakingAction) {}

    private func state(balances: [StakingBalanceInfo]?, yield: StakingYieldInfo?) -> StakingManagerState {
        guard let yield, !yield.validators.isEmpty else {
            return .notEnabled
        }

        guard yield.isAvailable else {
            return .temporaryUnavailable(yield)
        }

        let stakingBalances = balances?.map { balance in
            mapToStakingBalance(balance: balance, yield: yield)
        }

        guard let stakingBalances, !stakingBalances.isEmpty else {
            return .availableToStake(yield)
        }

        return .staked(.init(balances: stakingBalances, yieldInfo: yield, canStakeMore: false))
    }
}
