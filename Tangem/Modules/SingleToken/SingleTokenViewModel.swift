//
//  SingleTokenViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk
import TangemSwapping

class SingleTokenBaseViewModel {
    @Injected(\.keysManager) var keysManager: KeysManager
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    @Published var alert: AlertBinder? = nil
    @Published var transactionHistoryState: TransactionsListView.State = .loading
    @Published var isReloadingTransactionHistory: Bool = false

    @Published var actionButtons: [ButtonWithIconInfo] = []

    private unowned let coordinator: SingleTokenRoutable

    let swappingUtils = SwappingAvailableUtils()
    let exchangeUtility: ExchangeCryptoUtility

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let userTokensManager: UserTokensManager

    lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()

    var availableActions: [TokenActionType] = []
    private var bag = Set<AnyCancellable>()

    var canBuyCrypto: Bool { exchangeUtility.buyAvailable }

    var canSend: Bool {
        guard canSignLongTransactions else {
            return false
        }

        return walletModel.wallet.canSend(amountType: amountType)
    }

    var canSignLongTransactions: Bool {
        if NFCUtils.isPoorNfcQualityDevice,
           case .solana = blockchain {
            return false
        } else {
            return true
        }
    }

    var blockchainNetwork: BlockchainNetwork { walletModel.blockchainNetwork }

    var amountType: Amount.AmountType { walletModel.amountType }

    var blockchain: Blockchain { blockchainNetwork.blockchain }

    var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        userTokensManager: UserTokensManager,
        exchangeUtility: ExchangeCryptoUtility,
        coordinator: SingleTokenRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
        self.userTokensManager = userTokensManager
        self.exchangeUtility = exchangeUtility
        self.coordinator = coordinator

        prepareSelf()
    }

    func openExplorer() {
        #warning("This will be changed after, for now there is no solution for tx history with multiple addresses")
        guard let url = walletModel.exploreURL(for: 0, token: amountType.token) else {
            return
        }

        openExplorer(at: url)
    }

    func reloadHistory() {
        isReloadingTransactionHistory = true
        walletModel.updateTransactionsHistory()
            .sink { [weak self] completion in
                self?.isReloadingTransactionHistory = false
            } receiveValue: { _ in }
            .store(in: &bag)
    }

    func openBuy() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let token = amountType.token, blockchain == .ethereum(testnet: true) {
            testnetBuyCryptoService.buyCrypto(.erc20Token(
                token,
                walletModel: walletModel,
                signer: userWalletModel.signer
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
}

// MARK: - Setup functions

extension SingleTokenBaseViewModel {
    private func prepareSelf() {
        bind()
        setupActionButtons()
        loadSwappingState()
        updateActionButtons()
    }

    private func setupActionButtons() {
        let listBuilder = TokenActionListBuilder()
        let canExchange = userWalletModel.config.isFeatureVisible(.exchange)
        availableActions = listBuilder.buildActions(canExchange: canExchange, exchangeUtility: exchangeUtility)
    }

    private func bind() {
        walletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] newState in
                AppLog.shared.debug("Token details receive new wallet model state: \(newState)")
                self?.updateActionButtons()
            }
            .store(in: &bag)

        walletModel.transactionHistoryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                AppLog.shared.debug("New transaction history state: \(newState)")
                self?.updateHistoryState(to: newState)
            }
            .store(in: &bag)
    }

    private func updateActionButtons() {
        let buttons = availableActions.map { type in
            let isDisabled = isButtonDisabled(with: type)

            return ButtonWithIconInfo(title: type.title, icon: type.icon, action: { [weak self] in
                self?.action(for: type)?()
            }, disabled: isDisabled)
        }

        actionButtons = buttons
    }

    private func updateHistoryState(to newState: WalletModel.TransactionHistoryState) {
        switch newState {
        case .notSupported:
            transactionHistoryState = .notSupported
        case .notLoaded:
            transactionHistoryState = .loading
            walletModel.updateTransactionsHistory()
                .sink()
                .store(in: &bag)
        case .loading:
            if case .notLoaded = newState {
                transactionHistoryState = .loading
            }
        case .failedToLoad(let error):
            transactionHistoryState = .error(error)
        case .loaded:
            let txListItems = TransactionHistoryMapper().makeTransactionListItems(from: walletModel.transactions)
            transactionHistoryState = .loaded(txListItems)
        }
    }

    private func loadSwappingState() {
        guard userWalletModel.config.isFeatureVisible(.swapping) else {
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

    private func action(for buttonType: TokenActionType) -> (() -> Void)? {
        switch buttonType {
        case .buy: return openBuyCryptoIfPossible
        case .send: return openSend
        case .receive: return openReceive
        case .exchange: return openExchange
        case .sell: return openSell
        }
    }
}

// MARK: - Navigation

extension SingleTokenBaseViewModel {
    func openReceive() {
        let infos = walletModel.wallet.addresses.map { address in
            ReceiveAddressInfo(address: address.value, type: address.type, addressQRImage: QrCodeGenerator.generateQRCode(from: address.value))
        }
        coordinator.openReceiveScreen(amountType: amountType, blockchain: blockchain, addressInfos: infos)
    }

    func openBuyCryptoIfPossible() {
        Analytics.log(.buttonBuy)
        if tangemApiService.geoIpRegionCode == LanguageCode.ru {
            coordinator.openBankWarning { [weak self] in
                self?.openBuy()
            } declineCallback: { [weak self] in
                self?.coordinator.openP2PTutorial()
            }
        } else {
            openBuy()
        }
    }

    func openSend() {
        guard
            let amountToSend = walletModel.wallet.amounts[amountType],
            // [REDACTED_TODO_COMMENT]
            let cardViewModel = userWalletModel as? CardViewModel
        else { return }

        Analytics.log(.buttonSend)
        coordinator.openSend(
            amountToSend: amountToSend,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardViewModel
        )
    }

    func openExchange() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .swapping) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard
            let sourceCurrency = CurrencyMapper().mapToCurrency(amountType: amountType, in: blockchain),
            let ethereumNetworkProvider = walletModel.ethereumNetworkProvider,
            let ethereumTransactionProcessor = walletModel.ethereumTransactionProcessor
        else { return }

        var referrer: SwappingReferrerAccount?

        if let account = keysManager.swapReferrerAccount {
            referrer = SwappingReferrerAccount(address: account.address, fee: account.fee)
        }

        let input = CommonSwappingModulesFactory.InputModel(
            userTokensManager: userTokensManager,
            wallet: walletModel.wallet,
            blockchainNetwork: walletModel.blockchainNetwork,
            sender: walletModel.transactionSender,
            signer: userWalletModel.signer,
            transactionCreator: walletModel.transactionCreator,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionProcessor: ethereumTransactionProcessor,
            logger: AppLog.shared,
            referrer: referrer,
            source: sourceCurrency,
            walletModelTokens: userTokensManager.getAllTokens(for: walletModel.blockchainNetwork)
        )

        coordinator.openSwapping(input: input)
    }

    func openSell() {
        Analytics.log(.buttonSell)

        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
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
        // [REDACTED_TODO_COMMENT]
        guard let cardViewModel = userWalletModel as? CardViewModel else {
            return
        }

        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator.openSendToSell(
            amountToSend: amount,
            destination: request.targetAddress,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardViewModel
        )
    }

    func openExplorer(at url: URL) {
        Analytics.log(.buttonExplore)
        coordinator.openExplorer(at: url, blockchainDisplayName: blockchainNetwork.blockchain.displayName)
    }
}

extension SingleTokenBaseViewModel: ActionButtonsProvider {
    var buttonsPublisher: AnyPublisher<[ButtonWithIconInfo], Never> { $actionButtons.eraseToAnyPublisher() }
}
