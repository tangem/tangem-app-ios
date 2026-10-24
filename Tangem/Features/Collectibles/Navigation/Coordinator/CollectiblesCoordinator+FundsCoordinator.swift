//
//  CollectiblesCoordinator+FundsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemCollectibles
import TangemFoundation
import TangemUI

// MARK: - CollectiblesAccountRoutable

extension CollectiblesCoordinator: CollectiblesAccountRoutable {
    func openAddFunds(account: CollectiblesVaultUsdcAccount) {
        fundsCoordinator?.openAddFunds(account: account)
    }
}

// MARK: - FundsCoordinator

extension CollectiblesCoordinator {
    final class FundsCoordinator: CoordinatorObject, SendFeeCurrencyNavigating {
        // MARK: - Properties

        @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
        @Injected(\.floatingSheetPresentingStateProvider)
        private var sheetStateProvider: any FloatingSheetPresentingStateProvider

        let dismissAction: Action<Void>
        let popToRootAction: Action<PopToRootOptions>

        private var options: Options?
        private var awaitDepositCancellable: AnyCancellable?
        private var addFundsFollowUp: AddFundsFollowUp?

        // MARK: - Publishers

        @Published var addFundsSheet: CollectiblesAddFundsSheetViewModel?
        @Published var sendCoordinator: SendCoordinator?
        @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?

        // MARK: - Init

        required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
            self.dismissAction = dismissAction
            self.popToRootAction = popToRootAction
        }

        // MARK: - Methods

        func start(with options: Options) {
            self.options = options
        }

        @MainActor
        func openAddFunds(account: CollectiblesVaultUsdcAccount) {
            guard addFundsSheet == nil, !sheetStateProvider.hasPresentedSheet, let options else {
                return
            }

            let tokenItem = CollectiblesChainEnvironment.usdcTokenItem(mint: account.mint)
            let swapParameters = CollectiblesSwapParametersFactory.make(
                accountModel: options.accountModel,
                userWalletInfo: options.userWalletInfo,
                walletModelsProvider: options.walletModelsProvider,
                tokenItem: tokenItem,
                fundingAddress: account.address
            )
            let sheet = CollectiblesAddFundsSheetViewModel(
                input: .init(address: account.address, tokenItem: tokenItem, swapParameters: swapParameters),
                routable: self
            )

            guard #available(iOS 26.0, *) else {
                floatingSheetPresenter.enqueue(sheet: sheet)
                return
            }

            addFundsSheet = sheet
        }

        @MainActor
        func addFundsSheetDidDismiss() {
            guard let followUp = addFundsFollowUp else {
                return
            }

            addFundsFollowUp = nil
            present(followUp)
        }
    }
}

// MARK: - Options

extension CollectiblesCoordinator.FundsCoordinator {
    struct Options {
        let accountModel: any CollectiblesBalanceSource & CollectiblesDepositAwaiter & BaseAccountModel
        let userWalletInfo: UserWalletInfo
        let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider
    }
}

// MARK: - AddFundsFollowUp

private extension CollectiblesCoordinator.FundsCoordinator {
    enum AddFundsFollowUp {
        case swap(PredefinedSwapParameters)
        case receive(address: String, tokenItem: TokenItem)
    }
}

// MARK: - CollectiblesAddFundsRoutable

extension CollectiblesCoordinator.FundsCoordinator: CollectiblesAddFundsRoutable {
    func openSwap(parameters: PredefinedSwapParameters) {
        closeAddFunds(then: .swap(parameters))
    }

    func openReceive(address: String, tokenItem: TokenItem) {
        closeAddFunds(then: .receive(address: address, tokenItem: tokenItem))
    }

    func closeAddFunds() {
        closeAddFunds(then: nil)
    }
}

// MARK: - Private logic

private extension CollectiblesCoordinator.FundsCoordinator {
    @MainActor
    func closeAddFunds(then followUp: AddFundsFollowUp?) {
        guard #available(iOS 26.0, *) else {
            floatingSheetPresenter.removeActiveSheet()

            if let followUp {
                present(followUp)
            }

            return
        }

        addFundsFollowUp = followUp
        addFundsSheet = nil
    }

    @MainActor
    func present(_ followUp: AddFundsFollowUp) {
        switch followUp {
        case .swap(let parameters):
            presentSwap(parameters: parameters)
        case .receive(let address, let tokenItem):
            presentReceive(address: address, tokenItem: tokenItem)
        }
    }

    @MainActor
    func presentSwap(parameters: PredefinedSwapParameters) {
        let coordinator = makeSendCoordinator()
        coordinator.start(
            with: .init(
                type: .swap(parameters),
                source: .main,
                onTransactionDispatched: { [weak self] in self?.awaitDeposit() }
            )
        )
        sendCoordinator = coordinator
    }

    @MainActor
    func presentReceive(address: String, tokenItem: TokenItem) {
        let viewModel = AvailabilityReceiveFlowFactory(
            flow: .crypto,
            tokenItem: tokenItem,
            addressTypesProvider: SingleAddressReceiveAddressTypesProvider(address: address, colorScheme: .whiteBlack)
        )
        .makeAvailabilityReceiveFlow()

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    @MainActor
    func awaitDeposit() {
        guard let accountModel = options?.accountModel else {
            return
        }

        awaitDepositCancellable = Task { await accountModel.awaitDeposit() }.eraseToAnyCancellable()
    }
}
