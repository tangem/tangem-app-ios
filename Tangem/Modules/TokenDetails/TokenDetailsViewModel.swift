//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk
import TangemSwapping

final class TokenDetailsViewModel: SingleTokenBaseViewModel, ObservableObject {
    @Injected(\.expressPendingTransactionsRepository) private var expressPendingTxRepository: ExpressPendingTransactionRepository

    @Published private var balance: LoadingValue<BalanceInfo> = .loading
    @Published var actionSheet: ActionSheetBinder?
    @Published var shouldShowNotificationsWithAnimation: Bool = false
    @Published var pendingExpressTransactions: [PendingExpressTransactionView.Info] = []

    private(set) var balanceWithButtonsModel: BalanceWithButtonsViewModel!
    private(set) lazy var tokenDetailsHeaderModel: TokenDetailsHeaderViewModel = .init(tokenItem: tokenItem)

    private unowned let coordinator: TokenDetailsRoutable
    private var bag = Set<AnyCancellable>()
    private var notificatioChangeSubscription: AnyCancellable?

    var tokenItem: TokenItem {
        switch amountType {
        case .token(let token):
            return .token(token, blockchain)
        default:
            return .blockchain(blockchain)
        }
    }

    var iconUrl: URL? {
        guard let id = tokenItem.id else {
            return nil
        }

        return TokenIconURLBuilder().iconURL(id: id)
    }

    var customTokenColor: Color? {
        tokenItem.token?.customTokenColor
    }

    var canHideToken: Bool { userWalletModel.isMultiWallet }

    init(
        cardModel: CardViewModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        notificationManager: NotificationManager,
        coordinator: TokenDetailsRoutable,
        tokenRouter: SingleTokenRoutable
    ) {
        self.coordinator = coordinator
        super.init(
            userWalletModel: cardModel,
            walletModel: walletModel,
            exchangeUtility: exchangeUtility,
            notificationManager: notificationManager,
            tokenRouter: tokenRouter
        )
        balanceWithButtonsModel = .init(balanceProvider: self, buttonsProvider: self)

        prepareSelf()
    }

    func onAppear() {
        Analytics.log(event: .detailsScreenOpened, params: [Analytics.ParameterKey.token: tokenItem.currencySymbol])
    }

    func onDidAppear() {
        shouldShowNotificationsWithAnimation = true
    }

    override func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .openNetworkCurrency:
            openNetworkCurrency()
        default:
            super.didTapNotificationButton(with: id, action: action)
        }
    }

    override func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        self.actionSheet = actionSheet
    }
}

// MARK: - Hide token

extension TokenDetailsViewModel {
    func hideTokenButtonAction() {
        if userWalletModel.userTokensManager.canRemove(walletModel.tokenItem, derivationPath: walletModel.blockchainNetwork.derivationPath) {
            showHideWarningAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    private func showUnableToHideAlert() {
        let message = Localization.tokenDetailsUnableHideAlertMessage(
            currencySymbol,
            blockchain.displayName
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsUnableHideAlertTitle(currencySymbol),
            message: message,
            primaryButton: .default(Text(Localization.commonOk))
        )
    }

    private func showHideWarningAlert() {
        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsHideAlertTitle(currencySymbol),
            message: Localization.tokenDetailsHideAlertMessage,
            primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide)) { [weak self] in
                self?.hideToken()
            },
            secondaryButton: .cancel()
        )
    }

    private func hideToken() {
        Analytics.log(
            event: .buttonRemoveToken,
            params: [
                Analytics.ParameterKey.token: currencySymbol,
                Analytics.ParameterKey.source: Analytics.ParameterValue.token.rawValue,
            ]
        )

        userWalletModel.userTokensManager.remove(walletModel.tokenItem, derivationPath: walletModel.blockchainNetwork.derivationPath)
        dismiss()
    }
}

// MARK: - Setup functions

private extension TokenDetailsViewModel {
    private func prepareSelf() {
        updateBalance(walletModelState: walletModel.state)
        tokenNotificationInputs = notificationManager.notificationInputs
        bind()
    }

    private func bind() {
        walletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] newState in
                AppLog.shared.debug("Token details receive new wallet model state: \(newState)")
                self?.updateBalance(walletModelState: newState)
            }
            .store(in: &bag)

        expressPendingTxRepository.pendingTransactionsPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .map { viewModel, records in
                let blockchainNetwork = viewModel.walletModel.blockchainNetwork
                let tokenItem = viewModel.walletModel.tokenItem

                return records.filter { txRecord in
                    let isSameBlockchain = txRecord.sourceTokenTxInfo.blockchainNetwork == blockchainNetwork
                        || txRecord.destinationTokenTxInfo.blockchainNetwork == blockchainNetwork
                    let isSameTokenItem = txRecord.sourceTokenTxInfo.tokenItem == tokenItem
                        || txRecord.destinationTokenTxInfo.tokenItem == tokenItem

                    return isSameBlockchain && isSameTokenItem
                }
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, records in
                let iconBuilder = TokenIconInfoBuilder()
                viewModel.pendingExpressTransactions = records.map {
                    let sourceTokenItem = $0.sourceTokenTxInfo.tokenItem
                    let destinationTokenItem = $0.destinationTokenTxInfo.tokenItem
                    return .init(
                        id: $0.expressTransactionId,
                        providerName: $0.provider.name,
                        sourceIconInfo: iconBuilder.build(from: sourceTokenItem, isCustom: $0.sourceTokenTxInfo.isCustom),
                        sourceAmountText: "\($0.sourceTokenTxInfo.amount) \(sourceTokenItem.currencySymbol)",
                        destinationIconInfo: iconBuilder.build(from: destinationTokenItem, isCustom: $0.destinationTokenTxInfo.isCustom),
                        destinationCurrencySymbol: destinationTokenItem.currencySymbol,
                        state: .inProgress
                    ) { transactionId in
                        print("Attempting to open pending tx with id: \(transactionId)")
                    }
                }
            }
            .store(in: &bag)
    }

    private func updateBalance(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created, .loading:
            balance = .loading
        case .idle, .noAccount:
            balance = .loaded(.init(
                balance: walletModel.balance,
                fiatBalance: walletModel.fiatBalance
            ))
        case .failed(let message):
            balance = .failedToLoad(error: message)
        case .noDerivation:
            // User can't reach this screen without derived keys
            balance = .failedToLoad(error: "")
        }
    }
}

// MARK: - Navigation functions

private extension TokenDetailsViewModel {
    func dismiss() {
        coordinator.dismiss()
    }

    func openNetworkCurrency() {
        guard
            case .token(_, let blockchain) = walletModel.tokenItem,
            let networkCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem == .blockchain(blockchain) && $0.blockchainNetwork == walletModel.blockchainNetwork
            })
        else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator.openNetworkCurrency(for: networkCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}

extension TokenDetailsViewModel: BalanceProvider {
    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> { $balance.eraseToAnyPublisher() }
}
