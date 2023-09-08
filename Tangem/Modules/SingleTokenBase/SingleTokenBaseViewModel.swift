//
//  SingleTokenBaseViewModel.swift
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
import CombineExt

class SingleTokenBaseViewModel: NotificationTapDelegate {
    @Published var alert: AlertBinder? = nil
    @Published var transactionHistoryState: TransactionsListView.State = .loading
    @Published var isReloadingTransactionHistory: Bool = false
    @Published var actionButtons: [ButtonWithIconInfo] = []
    @Published private(set) var tokenNotificationInputs: [NotificationViewInput] = []

    lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()

    let swappingUtils = SwappingAvailableUtils()
    let exchangeUtility: ExchangeCryptoUtility
    let notificationManager: NotificationManager

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel

    var availableActions: [TokenActionType] = []

    private let tokenRouter: SingleTokenRoutable

    private var transactionHistoryBag: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    var canBuyCrypto: Bool { exchangeUtility.buyAvailable }

    var canSend: Bool { walletModel.canSendTransaction }

    var blockchainNetwork: BlockchainNetwork { walletModel.blockchainNetwork }

    var amountType: Amount.AmountType { walletModel.amountType }

    var blockchain: Blockchain { blockchainNetwork.blockchain }

    var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    lazy var transactionHistoryMapper: TransactionHistoryMapper = .init(currencySymbol: currencySymbol, walletAddress: walletModel.defaultAddress)

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        notificationManager: NotificationManager,
        tokenRouter: SingleTokenRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
        self.exchangeUtility = exchangeUtility
        self.notificationManager = notificationManager
        self.tokenRouter = tokenRouter

        prepareSelf()
    }

    func openExplorer() {
        #warning("This will be changed after, for now there is no solution for tx history with multiple addresses")
        guard let url = walletModel.exploreURL(for: 0, token: amountType.token) else {
            return
        }

        openExplorer(at: url)
    }

    func fetchMoreHistory() -> FetchMore? {
        guard let transactionHistoryService = walletModel.transactionHistoryService,
              transactionHistoryService.canFetchMore else {
            return nil
        }

        return FetchMore { [weak self] in
            self?.loadHistory()
        }
    }

    func reloadHistory() {
        Analytics.log(event: .buttonReload, params: [.token: currencySymbol])

        // We should reset transaction history to initial state here
        walletModel.transactionHistoryService?.reset()

        DispatchQueue.main.async {
            self.isReloadingTransactionHistory = true
        }

        loadHistory()
    }

    func loadHistory() {
        transactionHistoryBag = walletModel
            .updateTransactionsHistory()
            .receive(on: DispatchQueue.main)
            .receiveCompletion { [weak self] _ in
                self?.isReloadingTransactionHistory = false
            }
    }

    // We need to keep this not in extension because we may want to override this logic and
    // implementation from extensions can't be overriden
    func didTapNotification(with id: NotificationViewId) {}

    // We need to keep this not in extension because we may want to override this logic and
    // implementation from extensions can't be overriden
    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .buyCrypto:
            openBuyCryptoIfPossible()
        default:
            break
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
        loadHistory()
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

        notificationManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.tokenNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        tokenRouter.errorAlertPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.alert, on: self, ownership: .weak)
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
        case .loading:
            if case .notLoaded = newState {
                transactionHistoryState = .loading
            }
        case .error(let error):
            transactionHistoryState = .error(error)
        case .loaded(let records):
            let listItems = transactionHistoryMapper.mapTransactionListItem(from: records)
            transactionHistoryState = .loaded(listItems)
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
        case .copyAddress, .hide: return nil
        }
    }
}

// MARK: - Navigation

extension SingleTokenBaseViewModel {
    func openReceive() {
        tokenRouter.openReceive(walletModel: walletModel)
    }

    func openBuyCryptoIfPossible() {
        tokenRouter.openBuyCryptoIfPossible(walletModel: walletModel)
    }

    func openSend() {
        tokenRouter.openSend(walletModel: walletModel)
    }

    func openExchange() {
        tokenRouter.openExchange(walletModel: walletModel)
    }

    func openSell() {
        tokenRouter.openSell(for: walletModel)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        tokenRouter.openSendToSell(with: request, for: walletModel)
    }

    func openExplorer(at url: URL) {
        tokenRouter.openExplorer(at: url, for: walletModel)
    }
}

extension SingleTokenBaseViewModel: ActionButtonsProvider {
    var buttonsPublisher: AnyPublisher<[ButtonWithIconInfo], Never> { $actionButtons.eraseToAnyPublisher() }
}
