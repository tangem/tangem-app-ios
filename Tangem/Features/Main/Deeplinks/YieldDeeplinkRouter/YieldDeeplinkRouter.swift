//
//  YieldDeeplinkRouter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Combine
import Foundation
import TangemFoundation

final class YieldDeeplinkRouter {
    // MARK: - Typealiases

    typealias OpenYieldPromoAction = (Decimal, YieldModuleFlowFactory) -> Void
    typealias OpenYieldActiveAction = (YieldModuleFlowFactory) -> Void
    typealias DiscardIncomingAction = () -> Void
    typealias FinishAction = () -> Void

    // MARK: - Dependencies

    private let discardIncomingAction: DiscardIncomingAction
    private let openYieldPromoAction: OpenYieldPromoAction
    private let openYieldActiveAction: OpenYieldActiveAction
    private let onFinish: FinishAction

    // MARK: - Properties

    private var subscription: AnyCancellable?
    private var isFinished = false

    // MARK: - Init

    init(
        discardIncomingAction: @escaping DiscardIncomingAction,
        openYieldPromoAction: @escaping OpenYieldPromoAction,
        openYieldActiveAction: @escaping OpenYieldActiveAction,
        onFinish: @escaping FinishAction
    ) {
        self.discardIncomingAction = discardIncomingAction
        self.openYieldPromoAction = openYieldPromoAction
        self.openYieldActiveAction = openYieldActiveAction
        self.onFinish = onFinish
    }

    // MARK: - Public API

    func handle(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        guard
            let yieldModuleManager = walletModel.yieldModuleManager,
            let flowFactory = makeYieldModuleFlowFactory(walletModel: walletModel, userWalletModel: userWalletModel, manager: yieldModuleManager)
        else {
            discardIncomingAction()
            finish()
            return
        }

        if let currentState = yieldModuleManager.state, handleYieldState(currentState, flowFactory: flowFactory) {
            finish()
            return
        }

        subscription = yieldModuleManager.statePublisher
            .compactMap { $0 }
            .first(where: shouldHandleYieldState)
            .timeout(.seconds(Constants.timeout), scheduler: DispatchQueue.main)
            .receiveOnMain()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.subscription = nil

                    if case .failure = completion {
                        self?.discardIncomingAction()
                        self?.finish()
                    }
                },
                receiveValue: { [weak self] state in
                    guard let self else { return }

                    subscription = nil

                    if !handleYieldState(state, flowFactory: flowFactory) {
                        discardIncomingAction()
                    }

                    finish()
                }
            )
    }
}

// MARK: - State handling

private extension YieldDeeplinkRouter {
    func finish() {
        guard !isFinished else { return }

        isFinished = true
        onFinish()
    }

    func shouldHandleYieldState(_ state: YieldModuleManagerStateInfo) -> Bool {
        if state.state.isEffectivelyActive {
            return true
        }

        if case .notActive = state.state, state.marketInfo?.apy != nil {
            return true
        }

        return false
    }

    @discardableResult
    func handleYieldState(_ state: YieldModuleManagerStateInfo, flowFactory: YieldModuleFlowFactory) -> Bool {
        if state.state.isEffectivelyActive {
            openYieldActiveAction(flowFactory)
            return true
        }

        if case .notActive = state.state, let apy = state.marketInfo?.apy {
            openYieldPromoAction(apy, flowFactory)
            return true
        }

        return false
    }
}

// MARK: - Helpers

private extension YieldDeeplinkRouter {
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
}

private extension YieldDeeplinkRouter {
    enum Constants {
        static let timeout: TimeInterval = 10
    }
}
