//
//  WalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk

class WalletModel {
    @Injected(\.ratesRepository) private var ratesRepository: RatesRepository
    @Injected(\.tokenQuotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    var walletModelId: WalletModel.Id {
        .init(blockchainNetwork: blockchainNetwork, amountType: amountType)
    }

    /// Listen for fiat and balance changes. This publisher will not be called if the is nothing changed. Use `update(silent:)` for waiting for update
    var walletDidChangePublisher: AnyPublisher<WalletModel.State, Never> {
        _walletDidChangePublisher.eraseToAnyPublisher()
    }

    var state: State {
        _state.value
    }

    /// Listen tx history changes
    var transactionHistoryPublisher: AnyPublisher<TransactionHistoryState, Never> {
        transactionHistoryState()
    }

    var shoudShowFeeSelector: Bool {
        walletManager.allowsFeeSelection
    }

    var tokenItem: TokenItem {
        switch amountType {
        case .coin, .reserve:
            return .blockchain(wallet.blockchain)
        case .token(let token):
            return .token(token, wallet.blockchain)
        }
    }

    var name: String {
        switch amountType {
        case .coin, .reserve:
            return wallet.blockchain.displayName
        case .token(let token):
            return token.name
        }
    }

    var isMainToken: Bool {
        switch amountType {
        case .coin, .reserve:
            return true
        case .token:
            return false
        }
    }

    var balanceValue: Decimal? {
        if state.isNoAccount {
            return 0
        }

        return wallet.amounts[amountType]?.value
    }

    var balance: String {
        guard let balanceValue else { return "" }

        return formatter.formatCryptoBalance(balanceValue, currencyCode: tokenItem.currencySymbol)
    }

    var isZeroAmount: Bool {
        wallet.amounts[amountType]?.isZero ?? true
    }

    var fiatBalance: String {
        formatter.formatFiatBalance(fiatValue)
    }

    var fiatValue: Decimal? {
        guard let balanceValue,
              let currencyId = tokenItem.currencyId else {
            return nil
        }

        return converter.convertToFiat(value: balanceValue, from: currencyId)
    }

    var rateFormatted: String {
        guard let rate else { return "" }

        return formatter.formatFiatBalance(rate, formattingOptions: .defaultFiatFormattingOptions)
    }

    var quote: TokenQuote? {
        tokenQuotesRepository.quote(for: tokenItem)
    }

    var hasPendingTransactions: Bool {
        wallet.hasPendingTx(for: amountType)
    }

    var wallet: Wallet { walletManager.wallet }

    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }

    var defaultAddress: String {
        wallet.defaultAddress.value
    }

    var isTestnet: Bool {
        wallet.blockchain.isTestnet
    }

    var incomingPendingTransactions: [LegacyTransactionRecord] {
        legacyTransactionMapper.mapToIncomingRecords(wallet.pendingIncomingTransactions)
    }

    var outgoingPendingTransactions: [LegacyTransactionRecord] {
        legacyTransactionMapper.mapToOutgoingRecords(wallet.pendingOutgoingTransactions)
    }

    var isEmptyIncludingPendingIncomingTxs: Bool {
        wallet.isEmpty && incomingPendingTransactions.isEmpty
    }

    var blockchainNetwork: BlockchainNetwork {
        if wallet.publicKey.derivationPath == nil { // cards without hd wallet
            return BlockchainNetwork(wallet.blockchain, derivationPath: nil)
        }

        return .init(wallet.blockchain, derivationPath: wallet.publicKey.derivationPath)
    }

    var qrReceiveMessage: String {
        // [REDACTED_TODO_COMMENT]
        let symbol = wallet.amounts[amountType]?.currencySymbol ?? wallet.blockchain.currencySymbol

        let currencyName: String
        if case .token(let token) = amountType {
            currencyName = token.name
        } else {
            currencyName = wallet.blockchain.displayName
        }

        return Localization.addressQrCodeMessageFormat(currencyName, symbol, wallet.blockchain.displayName)
    }

    var canSendTransaction: Bool {
        guard AppUtils().canSignLongTransactions(network: blockchainNetwork) else {
            return false
        }

        return wallet.canSend(amountType: amountType)
    }

    var sendBlockedReason: SendBlockedReason? {
        if !AppUtils().canSignLongTransactions(network: blockchainNetwork) {
            return .cantSignLongTransactions
        }

        guard
            let currentAmount = wallet.amounts[amountType],
            let token = amountType.token
        else {
            return nil
        }

        if wallet.hasPendingTx, !wallet.hasPendingTx(for: amountType) { // has pending tx for fee
            return .hasPendingCoinTx(symbol: blockchainNetwork.blockchain.currencySymbol)
        }

        // no fee
        if !wallet.hasPendingTx, !canSendTransaction, !currentAmount.isZero {
            return .notEnoughtFeeForTokenTx(
                tokenName: token.name,
                networkName: blockchainNetwork.blockchain.displayName,
                coinSymbol: blockchainNetwork.blockchain.currencySymbol
            )
        }

        return nil
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> {
        swapAvailabilityProvider
            .tokenItemsAvailableToSwapPublisher
            .contains { [weak self] itemsAvailableToSwap in
                guard let self else {
                    return false
                }

                return itemsAvailableToSwap[tokenItem] ?? false
            }
            .removeDuplicates()
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    var isDemo: Bool { demoBalance != nil }
    var demoBalance: Decimal?

    let amountType: Amount.AmountType
    let isCustom: Bool

    private let walletManager: WalletManager
    private let _transactionHistoryService: TransactionHistoryService?
    private var updateTimer: AnyCancellable?
    private var txHistoryUpdateSubscription: AnyCancellable?
    private var updateWalletModelSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()
    private var updatePublisher: PassthroughSubject<State, Never>?
    private var updateQueue = DispatchQueue(label: "walletModel_update_queue")
    private var _walletDidChangePublisher: CurrentValueSubject<State, Never> = .init(.created)
    private var _state: CurrentValueSubject<State, Never> = .init(.created)
    private var _rate: CurrentValueSubject<Decimal?, Never> = .init(nil)

    private var rate: Decimal? {
        guard let currencyId = tokenItem.currencyId else {
            return nil
        }

        return ratesRepository.rates[currencyId]
    }

    private let converter = BalanceConverter()
    private let formatter = BalanceFormatter()
    private var legacyTransactionMapper: LegacyTransactionMapper {
        LegacyTransactionMapper(formatter: formatter)
    }

    deinit {
        AppLog.shared.debug("🗑 \(self) deinit")
    }

    init(
        walletManager: WalletManager,
        transactionHistoryService: TransactionHistoryService?,
        amountType: Amount.AmountType,
        isCustom: Bool
    ) {
        self.walletManager = walletManager
        _transactionHistoryService = transactionHistoryService
        self.amountType = amountType
        self.isCustom = isCustom

        bind()
    }

    func bind() {
        AppSettings.shared
            .$selectedCurrencyCode
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .dropFirst()
            .receive(on: updateQueue)
            .flatMap { [weak self] _ in
                guard let self else {
                    return Just(()).eraseToAnyPublisher()
                }

                return Publishers
                    .CombineLatest(loadRates(), loadQuotes())
                    .mapToVoid()
                    .eraseToAnyPublisher()
            }
            .sink(receiveValue: {})
            .store(in: &bag)

        walletManager.statePublisher
            .filter { !$0.isInitialState }
            .receive(on: updateQueue)
            .sink { [weak self] newState in
                self?.walletManagerDidUpdate(newState)
            }
            .store(in: &bag)

        ratesRepository
            .ratesPublisher
            .compactMap { [tokenItem] rates -> Decimal? in
                guard let currencyId = tokenItem.currencyId else { return nil }

                return rates[currencyId]
            }
            .removeDuplicates()
            .sink { [weak self] rate in
                guard let self else { return }

                AppLog.shared.debug("🔄 Rate updated for \(self)")
                _rate.send(rate)
            }
            .store(in: &bag)

        _state
            .removeDuplicates()
            .combineLatest(_rate.removeDuplicates(), walletManager.walletPublisher)
            .map { $0.0 }
            .assign(to: \._walletDidChangePublisher.value, on: self, ownership: .weak)
            .store(in: &bag)
    }

    // MARK: - Update wallet model

    func generalUpdate(silent: Bool) -> AnyPublisher<Void, Never> {
        Publishers
            .CombineLatest(update(silent: silent), updateTransactionsHistory())
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    @discardableResult
    /// Do not use with flatMap.
    func update(silent: Bool) -> AnyPublisher<State, Never> {
        // If updating already in process return updating Publisher
        if let updatePublisher = updatePublisher {
            return updatePublisher.eraseToAnyPublisher()
        }

        // Keep this before the async call
        let newUpdatePublisher = PassthroughSubject<State, Never>()
        updatePublisher = newUpdatePublisher

        if case .loading = state {
            return newUpdatePublisher.eraseToAnyPublisher()
        }

        AppLog.shared.debug("🔄 Start updating \(self)")

        if !silent {
            updateState(.loading)
        }

        updateWalletModelSubscription = walletManager
            .updatePublisher()
            .combineLatest(loadRates(), loadQuotes())
            .receive(on: updateQueue)
            .sink { [weak self] newState, _, _ in
                guard let self else { return }

                AppLog.shared.debug("🔄 Finished common update for \(self)")

                updatePublisher?.send(mapState(newState))
                updatePublisher?.send(completion: .finished)
                updatePublisher = nil
            }

        return newUpdatePublisher.eraseToAnyPublisher()
    }

    private func walletManagerDidUpdate(_ walletManagerState: WalletManagerState) {
        switch walletManagerState {
        case .loaded:
            AppLog.shared.debug("🔄 Finished updating for \(self)")

            if let demoBalance {
                walletManager.wallet.add(coinValue: demoBalance)
            }
        case .failed:
            AppLog.shared.debug("🔄 Failed updating for \(self)")
        case .loading, .initial:
            break
        }

        updateState(mapState(walletManagerState))
    }

    private func mapState(_ walletManagerState: WalletManagerState) -> WalletModel.State {
        switch walletManagerState {
        case .loaded:
            return .idle
        case .failed(let error):
            switch error as? WalletError {
            case .noAccount(let message):
                return .noAccount(message: message)
            default:
                return .failed(error: error.detailedError.localizedDescription)
            }
        case .loading:
            return .loading
        case .initial:
            return .created
        }
    }

    private func updateState(_ state: State) {
        AppLog.shared.debug("🔄 Updating state for \(self). New state is \(state)")
        DispatchQueue.main.async { [weak self] in // captured as weak at call stack
            self?._state.value = state
        }
    }

    // MARK: - Load Rates

    private func loadRates() -> AnyPublisher<Void, Never> {
        guard let currencyId = tokenItem.currencyId else {
            return .just(output: ())
        }

        AppLog.shared.debug("🔄 Start loading rates for \(self)")

        return ratesRepository
            .loadRates(coinIds: [currencyId])
            .handleEvents(receiveOutput: { [weak self] _ in
                AppLog.shared.debug("🔄 Finished loading rates for \(String(describing: self))")
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    private func loadQuotes() -> AnyPublisher<Void, Never> {
        guard let currencyId = tokenItem.currencyId else {
            return .just(output: ())
        }

        AppLog.shared.debug("🔄 Start loading quotes for \(self)")

        return tokenQuotesRepository
            .loadQuotes(coinIds: [currencyId])
            .handleEvents(receiveOutput: { [weak self] _ in
                AppLog.shared.debug("🔄 Finished loading quotes for \(String(describing: self))")
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func startUpdatingTimer() {
        walletManager.setNeedsUpdate()
        AppLog.shared.debug("⏰ Starting updating timer for \(self)")
        updateTimer = Timer.TimerPublisher(
            interval: 10.0,
            tolerance: 0.1,
            runLoop: .main,
            mode: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            AppLog.shared.debug("⏰ Updating timer alarm ‼️ \(String(describing: self)) will be updated")
            self?.update(silent: false)
            self?.updateTimer?.cancel()
        }
    }

    func send(_ tx: Transaction, signer: TangemSigner) -> AnyPublisher<Void, Error> {
        if isDemo {
            return signer.sign(
                hash: Data.randomData(count: 32),
                walletPublicKey: wallet.publicKey
            )
            .mapToVoid()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        }

        return walletManager.send(tx, signer: signer)
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.startUpdatingTimer()
            })
            .receive(on: DispatchQueue.main)
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        if isDemo {
            let demoFees = DemoUtil().getDemoFee(for: walletManager.wallet.blockchain)
            return .justWithError(output: demoFees)
        }

        return walletManager.getFee(amount: amount, destination: destination)
    }

    func createTransaction(amountToSend: Amount, fee: Fee, destinationAddress: String) throws -> Transaction {
        try walletManager.createTransaction(amount: amountToSend, fee: fee, destinationAddress: destinationAddress)
    }
}

// MARK: - Helpers

extension WalletModel {
    func displayAddress(for index: Int) -> String {
        wallet.addresses[index].value
    }

    func shareAddressString(for index: Int) -> String {
        wallet.getShareString(for: wallet.addresses[index].value)
    }

    func exploreURL(for index: Int, token: Token? = nil) -> URL? {
        if isDemo {
            return nil
        }

        return wallet.getExploreURL(for: wallet.addresses[index].value, token: token)
    }

    func exploreTransactionURL(for hash: String) -> URL? {
        if isDemo {
            return nil
        }

        return wallet.getExploreURL(for: hash)
    }

    func getDecimalBalance(for type: Amount.AmountType) -> Decimal? {
        return wallet.amounts[type]?.value
    }
}

// MARK: - Transaction history

extension WalletModel {
    func updateTransactionsHistory() -> AnyPublisher<Void, Never> {
        guard let transactionHistoryService else {
            AppLog.shared.debug("TransactionsHistory for \(self) not supported")
            return .just(output: ())
        }

        return transactionHistoryService
            .update()
            .eraseToAnyPublisher()
    }

    private func transactionHistoryState() -> AnyPublisher<WalletModel.TransactionHistoryState, Never> {
        guard let transactionHistoryService else {
            return .just(output: .notSupported)
        }

        return transactionHistoryService
            .statePublisher
            .map { [weak transactionHistoryService] state -> WalletModel.TransactionHistoryState in
                switch state {
                case .initial:
                    return .notLoaded
                case .loading:
                    return .loading
                case .loaded:
                    return .loaded(items: transactionHistoryService?.items ?? [])
                case .failedToLoad(let error):
                    return .error(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - ExistentialDepositProvider

extension WalletModel {
    var existentialDepositWarning: String? {
        guard let existentialDepositProvider = walletManager as? ExistentialDepositProvider else {
            return nil
        }

        let blockchainName = blockchainNetwork.blockchain.displayName
        let existentialDepositAmount = existentialDepositProvider.existentialDeposit.string(roundingMode: .plain)
        return Localization.warningExistentialDepositMessage(blockchainName, existentialDepositAmount)
    }
}

// MARK: - RentProvider

extension WalletModel {
    func updateRentWarning() -> AnyPublisher<String?, Never> {
        guard let rentProvider = walletManager as? RentProvider else {
            return .just(output: nil)
        }

        return rentProvider.rentAmount()
            .zip(rentProvider.minimalBalanceForRentExemption())
            .receive(on: RunLoop.main)
            .map { [weak self] rentAmount, minimalBalanceForRentExemption in
                guard
                    let self = self,
                    let amount = wallet.amounts[.coin],
                    amount < minimalBalanceForRentExemption
                else {
                    return nil
                }

                return Localization.solanaRentWarning(rentAmount.description, minimalBalanceForRentExemption.description)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}

// MARK: - Interfaces

extension WalletModel {
    var blockchainDataProvider: BlockchainDataProvider {
        walletManager
    }

    var transactionCreator: TransactionCreator {
        walletManager
    }

    var transactionSender: TransactionSender {
        walletManager
    }

    var transactionPusher: TransactionPusher? {
        walletManager as? TransactionPusher
    }

    var withdrawalValidator: WithdrawalValidator? {
        walletManager as? WithdrawalValidator
    }

    var ethereumGasLoader: EthereumGasLoader? {
        walletManager as? EthereumGasLoader
    }

    var ethereumTransactionSigner: EthereumTransactionSigner? {
        walletManager as? EthereumTransactionSigner
    }

    var ethereumNetworkProvider: EthereumNetworkProvider? {
        walletManager as? EthereumNetworkProvider
    }

    var ethereumTransactionProcessor: EthereumTransactionProcessor? {
        walletManager as? EthereumTransactionProcessor
    }

    var transactionHistoryService: TransactionHistoryService? {
        _transactionHistoryService
    }

    var signatureCountValidator: SignatureCountValidator? {
        walletManager as? SignatureCountValidator
    }

    var hasRent: Bool {
        walletManager is RentProvider
    }
}
