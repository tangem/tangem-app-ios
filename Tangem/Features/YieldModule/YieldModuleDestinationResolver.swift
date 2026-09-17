//
//  YieldModuleDestinationResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

/// Where a token leads inside the Yield module.
enum YieldModuleDestination {
    case promo(apy: Decimal, flowFactory: YieldModuleFlowFactory)
    case active(flowFactory: YieldModuleFlowFactory)
}

/// Answers which Yield-mode screen a token opens. The answer depends on the module state, which is loaded
/// asynchronously, so a state that says neither is waited for until it does — or until the timeout gives up.
@MainActor
struct YieldModuleDestinationResolver {
    func resolve(walletModel: any WalletModel, userWalletModel: any UserWalletModel) async -> YieldModuleDestination? {
        guard
            let yieldModuleManager = walletModel.yieldModuleManager,
            let flowFactory = makeYieldModuleFlowFactory(walletModel: walletModel, userWalletModel: userWalletModel, manager: yieldModuleManager)
        else {
            return nil
        }

        if let currentState = yieldModuleManager.state, let destination = makeDestination(for: currentState, flowFactory: flowFactory) {
            return destination
        }

        let state = try? await yieldModuleManager.statePublisher
            .compactMap { $0 }
            .first(where: leadsToDestination)
            .timeout(.seconds(Constants.timeout), scheduler: DispatchQueue.main)
            .receiveOnMain()
            .async()

        return state.flatMap { makeDestination(for: $0, flowFactory: flowFactory) }
    }
}

// MARK: - Private

private extension YieldModuleDestinationResolver {
    func leadsToDestination(_ state: YieldModuleManagerStateInfo) -> Bool {
        makeDestinationKind(for: state) != nil
    }

    func makeDestination(for state: YieldModuleManagerStateInfo, flowFactory: YieldModuleFlowFactory) -> YieldModuleDestination? {
        switch makeDestinationKind(for: state) {
        case .promo(let apy):
            return .promo(apy: apy, flowFactory: flowFactory)
        case .active:
            return .active(flowFactory: flowFactory)
        case nil:
            return nil
        }
    }

    /// The part of the answer the state alone decides, so that waiting for a usable state and reading it
    /// can't drift apart.
    func makeDestinationKind(for state: YieldModuleManagerStateInfo) -> DestinationKind? {
        if state.state.isEffectivelyActive {
            return .active
        }

        if case .notActive = state.state, let apy = state.marketInfo?.effectiveApy {
            return .promo(apy: apy)
        }

        return nil
    }

    func makeYieldModuleFlowFactory(
        walletModel: any WalletModel,
        userWalletModel: any UserWalletModel,
        manager: YieldModuleManager
    ) -> YieldModuleFlowFactory? {
        guard walletModel.multipleTransactionsSender != nil else {
            return nil
        }

        let provider = WalletModelTransactionDispatcherProvider(walletModel: walletModel, signer: userWalletModel.signer)
        let dispatcher = provider.makeYieldModuleTransactionDispatcher()

        return CommonYieldModuleFlowFactory(
            walletModel: walletModel,
            yieldModuleManager: manager,
            transactionDispatcher: dispatcher
        )
    }

    enum DestinationKind {
        case promo(apy: Decimal)
        case active
    }

    enum Constants {
        static let timeout: TimeInterval = 10
    }
}
