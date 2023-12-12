//
//  TokenDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class TokenDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var tokenDetailsViewModel: TokenDetailsViewModel? = nil

    // MARK: - Child coordinators

    @Published var legacySendCoordinator: LegacySendCoordinator? = nil
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var swappingCoordinator: SwappingCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil

    // MARK: - Child view models

    @Published var warningBankCardViewModel: WarningBankCardViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel? = nil
    @Published var pendingExpressTxStatusBottomSheetViewModel: PendingExpressTxStatusBottomSheetViewModel? = nil

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let exchangeUtility = ExchangeCryptoUtility(
            blockchain: options.walletModel.blockchainNetwork.blockchain,
            address: options.walletModel.wallet.address,
            amountType: options.walletModel.amountType
        )
        let notificationManager = SingleTokenNotificationManager(walletModel: options.walletModel, swapPairService: options.swapPairService, contextDataProvider: options.cardModel)

        let tokenRouter = SingleTokenRouter(
            userWalletModel: options.cardModel,
            coordinator: self
        )

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            userWalletId: options.cardModel.userWalletId.stringValue,
            blockchainNetwork: options.walletModel.blockchainNetwork,
            tokenItem: options.walletModel.tokenItem
        )

        tokenDetailsViewModel = .init(
            cardModel: options.cardModel,
            walletModel: options.walletModel,
            exchangeUtility: exchangeUtility,
            notificationManager: notificationManager,
            pendingExpressTransactionsManager: pendingExpressTransactionsManager,
            coordinator: self,
            tokenRouter: tokenRouter
        )
        notificationManager.setupManager(with: tokenDetailsViewModel)
    }
}

// MARK: - Options

extension TokenDetailsCoordinator {
    struct Options {
        let cardModel: CardViewModel
        let walletModel: WalletModel
        let userTokensManager: UserTokensManager
        let swapPairService: SwapPairService
    }
}

// MARK: - TokenDetailsRoutable

extension TokenDetailsCoordinator: TokenDetailsRoutable {
    func openPendingExpressTransactionDetails(
        for pendingTransaction: PendingExpressTransaction,
        tokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager
    ) {
        pendingExpressTxStatusBottomSheetViewModel = .init(
            pendingTransaction: pendingTransaction,
            currentTokenItem: tokenItem,
            pendingTransactionsManager: pendingTransactionsManager
        )
    }
}

extension TokenDetailsCoordinator: SingleTokenBaseRoutable {
    func openReceiveScreen(amountType: Amount.AmountType, blockchain: Blockchain, addressInfos: [ReceiveAddressInfo]) {
        let tokenItem: TokenItem
        switch amountType {
        case .token(let token):
            tokenItem = .token(token, blockchain)
        default:
            tokenItem = .blockchain(blockchain)
        }
        receiveBottomSheetViewModel = .init(tokenItem: tokenItem, addressInfos: addressInfos)
    }

    func openBuyCrypto(at url: URL, closeUrl: String, action: @escaping (String) -> Void) {
        Analytics.log(.topupScreenOpened)
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonBuy,
            addLoadingIndicator: true,
            withCloseButton: true,
            urlActions: [
                closeUrl: { [weak self] response in
                    self?.modalWebViewModel = nil
                    action(response)
                },
            ]
        )
    }

    func openNetworkCurrency(for model: WalletModel, userWalletModel: UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
        guard let cardViewModel = userWalletModel as? CardViewModel else {
            return
        }

        #warning("[REDACTED_TODO_COMMENT]")
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let swapPairService = SwapPairService(walletModelsManager: cardViewModel.walletModelsManager, userWalletId: cardViewModel.userWalletId.stringValue)

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                cardModel: cardViewModel,
                walletModel: model,
                userTokensManager: userWalletModel.userTokensManager,
                swapPairService: swapPairService
            )
        )

        tokenDetailsCoordinator = coordinator
    }

    func openSellCrypto(at url: URL, sellRequestUrl: String, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonSell,
            addLoadingIndicator: true,
            withCloseButton: true,
            urlActions: [sellRequestUrl: action]
        )
    }

    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel, walletModel: WalletModel) {
        guard FeatureProvider.isAvailable(.sendV2) else {
            let coordinator = LegacySendCoordinator { [weak self] in
                self?.legacySendCoordinator = nil
            }
            let options = LegacySendCoordinator.Options(
                amountToSend: amountToSend,
                destination: nil,
                blockchainNetwork: blockchainNetwork,
                cardViewModel: cardViewModel
            )
            coordinator.start(with: options)
            legacySendCoordinator = coordinator
            return
        }

        let coordinator = SendCoordinator { [weak self] in
            self?.sendCoordinator = nil
        }
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            transactionSigner: cardViewModel.signer,
            type: .send
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel, walletModel: WalletModel) {
        guard FeatureProvider.isAvailable(.sendV2) else {
            let coordinator = LegacySendCoordinator { [weak self] in
                self?.legacySendCoordinator = nil
            }
            let options = LegacySendCoordinator.Options(
                amountToSend: amountToSend,
                destination: destination,
                blockchainNetwork: blockchainNetwork,
                cardViewModel: cardViewModel
            )
            coordinator.start(with: options)
            legacySendCoordinator = coordinator
            return
        }

        let coordinator = SendCoordinator { [weak self] in
            self?.sendCoordinator = nil
        }
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            transactionSigner: cardViewModel.signer,
            type: .sell(amount: amountToSend.value, destination: destination)
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void) {
        let delay = 0.6
        warningBankCardViewModel = .init(confirmCallback: { [weak self] in
            self?.warningBankCardViewModel = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                confirmCallback()
            }
        }, declineCallback: { [weak self] in
            self?.warningBankCardViewModel = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                declineCallback()
            }
        })
    }

    func openP2PTutorial() {
        modalWebViewModel = WebViewContainerViewModel(
            url: URL(string: "https://tangem.com/howtobuy.html")!,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            urlActions: [:]
        )
    }

    func openSwapping(input: CommonSwappingModulesFactory.InputModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.swappingCoordinator = nil
        }

        let factory = CommonSwappingModulesFactory(inputModel: input)
        let coordinator = SwappingCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        swappingCoordinator = coordinator
    }

    func openExpress(input: CommonExpressModulesFactory.InputModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.expressCoordinator = nil

            guard let navigationInfo else {
                return
            }

            self?.openNetworkCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
        }

        let factory = CommonExpressModulesFactory(inputModel: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        expressCoordinator = coordinator
    }

    func openExplorer(at url: URL, blockchainDisplayName: String) {
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonExplorerFormat(blockchainDisplayName),
            withCloseButton: true
        )
    }
}
