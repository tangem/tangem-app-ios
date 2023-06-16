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

final class TokenDetailsViewModel: ObservableObject {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var alert: AlertBinder? = nil

    @Published private var balance: LoadingValue<BalanceInfo> = .loading
    @Published private var actionButtons: [ButtonWithIconInfo] = []

    private(set) var balanceWithButtonsModel: BalanceWithButtonsViewModel!

    private unowned let coordinator: TokenDetailsRoutable
    private let swappingUtils = SwappingAvailableUtils()
    private let exchangeUtility: ExchangeCryptoUtility

    private let cardModel: CardViewModel
    private let walletModel: WalletModel
    private let blockchainNetwork: BlockchainNetwork
    private let amountType: Amount.AmountType

    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()

    private var availableActions: [TokenActionType] = []
    private var bag = Set<AnyCancellable>()
    private var refreshCancellable: AnyCancellable?

    private var canSend: Bool {
        guard cardModel.canSend else {
            return false
        }

        guard canSignLongTransactions else {
            return false
        }

        return walletModel.wallet.canSend(amountType: amountType)
    }

    private var canSignLongTransactions: Bool {
        if NFCUtils.isPoorNfcQualityDevice,
           case .solana = blockchain {
            return false
        } else {
            return true
        }
    }

    private var blockchain: Blockchain { blockchainNetwork.blockchain }

    private var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    init(
        cardModel: CardViewModel,
        walletModel: WalletModel,
        blockchainNetwork: BlockchainNetwork,
        amountType: Amount.AmountType,
        coordinator: TokenDetailsRoutable
    ) {
        self.coordinator = coordinator
        self.walletModel = walletModel
        self.cardModel = cardModel
        self.blockchainNetwork = blockchainNetwork
        self.amountType = amountType

        exchangeUtility = .init(blockchain: blockchainNetwork.blockchain, address: walletModel.wallet.address, amountType: amountType)
        balanceWithButtonsModel = .init(balanceProvider: self, buttonsProvider: self)

        prepareSelf()
    }

    func onAppear() {
        Analytics.log(.detailsScreenOpened)
        // [REDACTED_TODO_COMMENT]
    }

    func onRefresh(_ done: @escaping () -> Void) {
        Analytics.log(.refreshed)

        refreshCancellable = walletModel
            .update(silent: false)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                AppLog.shared.debug("♻️ Token wallet model loading state changed")
                withAnimation(.default.delay(0.2)) {
                    done()
                }
            } receiveValue: { _ in }
    }
}

// MARK: - Hide token

extension TokenDetailsViewModel {
    func hideTokenButtonAction() {
        if walletModel.canRemove(amountType: amountType) {
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
        Analytics.log(event: .buttonRemoveToken, params: [Analytics.ParameterKey.token: currencySymbol])

        cardModel.remove(amountType: amountType, blockchainNetwork: walletModel.blockchainNetwork)
        dismiss()
    }
}

// MARK: - Setup functions

private extension TokenDetailsViewModel {
    private func prepareSelf() {
        bind()
        setupActionButtons()
        loadSwappingState()
        updateActionButtons()
    }

    private func setupActionButtons() {
        let listBuilder = TokenActionListBuilder()

        availableActions = listBuilder.buildActions(for: cardModel, exchangeUtility: exchangeUtility)
    }

    private func bind() {
        walletModel.$state
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] newState in
                AppLog.shared.debug("Token details receive new wallet model state: \(newState)")
                self?.updateBalance(walletModelState: newState)
                self?.updateActionButtons()
            }
            .store(in: &bag)
    }

    private func updateBalance(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created, .loading:
            balance = .loading
        case .idle:
            balance = .loaded(.init(
                balance: walletModel.getDecimalBalance(for: amountType) ?? 0,
                currencyCode: currencySymbol
            ))
        case .noAccount(let message), .failed(let message):
            balance = .failedToLoad(error: message)
        case .noDerivation:
            // User can't reach this screen without derived keys
            balance = .failedToLoad(error: "")
        }
    }

    private func updateActionButtons() {
        let buttons = availableActions.map { type in
            let action = action(for: type)
            let isDisabled = isButtonDisabled(with: type)

            return ButtonWithIconInfo(buttonType: type, action: action, disabled: isDisabled)
        }

        actionButtons = buttons
    }

    private func loadSwappingState() {
        guard cardModel.canShowSwapping else {
            return
        }

        var swappingSubscription: AnyCancellable?
        swappingSubscription = swappingUtils
            .canSwapPublisher(amountType: amountType, blockchain: blockchain)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                swappingSubscription = nil
                AppLog.shared.debug("Load swapping availability state completion: \(completion)")
            } receiveValue: { [weak self] isSwapAvailable in
                guard isSwapAvailable else { return }

                if let receiveIndex = self?.availableActions.firstIndex(of: .receive) {
                    self?.availableActions.insert(.exchange, at: receiveIndex + 1)
                } else {
                    self?.availableActions.append(.exchange)
                }

                self?.updateActionButtons()
            }
    }

    private func isButtonDisabled(with type: TokenActionType) -> Bool {
        guard case .send = type else {
            return false
        }

        return !canSend
    }

    private func action(for buttonType: TokenActionType) -> () -> Void {
        switch buttonType {
        case .buy: return openBuyCryptoIfPossible
        case .send: return openSend
        case .receive: return openReceive
        case .exchange: return openExchange
        case .sell: return openSell
        }
    }
}

// MARK: - Navigation functions

private extension TokenDetailsViewModel {
    func openReceive() {}

    func openBuyCryptoIfPossible() {
        Analytics.log(.buttonBuy)
        if tangemApiService.geoIpRegionCode == LanguageCode.ru {
            coordinator.openBankWarning {
                self.openBuy()
            } declineCallback: {
                self.coordinator.openP2PTutorial()
            }
        } else {
            openBuy()
        }
    }

    func openBuy() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let token = amountType.token, blockchain == .ethereum(testnet: true) {
            testnetBuyCryptoService.buyCrypto(.erc20Token(
                token,
                walletManager: walletModel.walletManager,
                signer: cardModel.signer
            ))
            return
        }

        guard let url = exchangeUtility.buyURL else { return }

        coordinator.openBuyCrypto(at: url, closeUrl: exchangeUtility.buyCryptoCloseURL) { [weak self] _ in
            guard let self else { return }
            Analytics.log(event: .tokenBought, params: [.token: currencySymbol])

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.walletModel.update(silent: true)
            }
        }
    }

    func openSend() {
        guard let amountToSend = walletModel.wallet.amounts[amountType] else { return }

        Analytics.log(.buttonSend)
        coordinator.openSend(
            amountToSend: amountToSend,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardModel
        )
    }

    func openExchange() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .swapping) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard
            let sourceCurrency = CurrencyMapper().mapToCurrency(amountType: amountType, in: blockchain)
        else { return }

        var referrer: SwappingReferrerAccount?

        if let account = keysManager.swapReferrerAccount {
            referrer = SwappingReferrerAccount(address: account.address, fee: account.fee)
        }

        let input = CommonSwappingModulesFactory.InputModel(
            userWalletModel: cardModel,
            walletModel: walletModel,
            sender: walletModel.walletManager,
            signer: cardModel.signer,
            logger: AppLog.shared,
            referrer: referrer,
            source: sourceCurrency
        )

        coordinator.openSwapping(input: input)
    }

    func openSell() {
        Analytics.log(.buttonSell)

        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard let url = exchangeUtility.sellURL else {
            return
        }

        coordinator.openSellCrypto(at: url, sellRequestUrl: exchangeUtility.sellCryptoCloseURL) { [weak self] response in
            if let request = self?.exchangeUtility.extractSellCryptoRequest(from: response) {
                self?.openSendToSell(with: request)
            }
        }
    }

    func openSendToSell(with request: SellCryptoRequest) {
        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator.openSendToSell(
            amountToSend: amount,
            destination: request.targetAddress,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardModel
        )
    }

    func dismiss() {
        coordinator.dismiss()
    }
}

extension TokenDetailsViewModel: BalanceProvider {
    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> { $balance.eraseToAnyPublisher() }
}

extension TokenDetailsViewModel: ActionButtonsProvider {
    var buttonsPublisher: AnyPublisher<[ButtonWithIconInfo], Never> { $actionButtons.eraseToAnyPublisher() }
}
