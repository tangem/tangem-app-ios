//
//  WalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import CombineExt
import BlockchainSdk
import TangemStaking
import TangemFoundation
import TangemExpress

class CommonWalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider
    @Injected(\.accountHealthChecker) private var accountHealthChecker: AccountHealthChecker

    let id: WalletModelId
    let tokenItem: TokenItem
    let isCustom: Bool
    var demoBalance: Decimal?

    // MARK: - Balance providers

    lazy var availableBalanceProvider = makeAvailableBalanceProvider()
    lazy var stakingBalanceProvider = makeStakingBalanceProvider()
    lazy var totalTokenBalanceProvider = makeTotalTokenBalanceProvider()

    lazy var fiatAvailableBalanceProvider = makeFiatAvailableBalanceProvider()
    lazy var fiatStakingBalanceProvider = makeFiatStakingBalanceProvider()
    lazy var fiatTotalTokenBalanceProvider = makeFiatTotalTokenBalanceProvider()

    /// Simple flag to check exactly BSDK balance
    var balanceState: WalletModelBalanceState? {
        switch wallet.amounts[tokenItem.amountType]?.value {
        case .none: .none
        case .zero: .zero
        case .some: .positive
        }
    }

    private let sendAvailabilityProvider: TransactionSendAvailabilityProvider
    private let tokenBalancesRepository: TokenBalancesRepository
    private let walletManager: WalletManager
    private let _stakingManager: StakingManager?
    private let _transactionHistoryService: TransactionHistoryService?
    private let featureManager: WalletModelFeaturesManager

    private var updateTimer: AnyCancellable?
    private var updateWalletModelSubscription: AnyCancellable?
    private var updatePublisher: PassthroughSubject<WalletModelState, Never>?

    private let amountType: Amount.AmountType
    private let blockchainNetwork: BlockchainNetwork
    private let _state: CurrentValueSubject<WalletModelState, Never> = .init(.created)
    private lazy var _rate: CurrentValueSubject<WalletModelRate, Never> = .init(.loading(cached: quotesRepository.quote(for: tokenItem)))

    private let _localPendingTransactionSubject: PassthroughSubject<Void, Never> = .init()
    private lazy var formatter = BalanceFormatter()

    private var bag = Set<AnyCancellable>()

    init(
        walletManager: WalletManager,
        stakingManager: StakingManager?,
        featureManager: WalletModelFeaturesManager,
        transactionHistoryService: TransactionHistoryService?,
        sendAvailabilityProvider: TransactionSendAvailabilityProvider,
        tokenBalancesRepository: TokenBalancesRepository,
        amountType: Amount.AmountType,
        shouldPerformHealthCheck: Bool,
        isCustom: Bool
    ) {
        self.walletManager = walletManager
        self.featureManager = featureManager
        _stakingManager = stakingManager
        _transactionHistoryService = transactionHistoryService
        self.amountType = amountType
        self.isCustom = isCustom
        self.sendAvailabilityProvider = sendAvailabilityProvider
        self.tokenBalancesRepository = tokenBalancesRepository

        blockchainNetwork = BlockchainNetwork(
            walletManager.wallet.blockchain,
            derivationPath: walletManager.wallet.publicKey.derivationPath
        )

        let tokenItem = switch amountType {
        case .coin, .reserve, .feeResource:
            TokenItem.blockchain(blockchainNetwork)
        case .token(let token):
            TokenItem.token(token, blockchainNetwork)
        }

        self.tokenItem = tokenItem
        id = WalletModelId(tokenItem: tokenItem)

        bind()
        performHealthCheckIfNeeded(shouldPerform: shouldPerformHealthCheck)
    }

    deinit {
        AppLogger.debug(self)
    }

    private func bind() {
        quotesRepository
            .quotesPublisher
            .dropFirst() // we need to drop first value because it's an empty dictionary
            .map { [currencyId = tokenItem.currencyId] quotes in
                currencyId.flatMap { quotes[$0] }
            }
            .removeDuplicates()
            .sink { [weak self] quote in
                self?.updateQuote(quote: quote)
            }
            .store(in: &bag)
    }

    private func performHealthCheckIfNeeded(shouldPerform: Bool) {
        if shouldPerform {
            DispatchQueue.main.async {
                self.accountHealthChecker.performAccountCheckIfNeeded(self.wallet.address)
            }
        }
    }

    // MARK: - State updates

    private func walletManagerDidUpdate(_ walletManagerState: WalletManagerState) {
        switch walletManagerState {
        case .loaded:
            if let demoBalance {
                walletManager.wallet.add(coinValue: demoBalance)
            }
        case .failed, .loading, .initial:
            break
        }

        updateState(mapState(walletManagerState))
    }

    private func mapState(_ walletManagerState: WalletManagerState) -> WalletModelState {
        switch walletManagerState {
        case .loaded:
            if let balance = wallet.amounts[amountType]?.value {
                return .loaded(balance)
            }

            return .failed(error: WalletModelError.balanceNotFound.localizedDescription)
        case .failed(WalletError.noAccount(let message, let amountToCreate)):
            return .noAccount(message: message, amountToCreate: amountToCreate)
        case .failed(let error):
            return .failed(error: error.detailedLocalizedDescription)
        case .loading:
            return .loading
        case .initial:
            return .created
        }
    }

    private func updateState(_ state: WalletModelState) {
        AppLogger.info(self, "Updating state. New state is \(state)")
        DispatchQueue.main.async { [weak self] in // captured as weak at call stack
            self?._state.value = state
        }
    }

    // MARK: - Quotes

    private func loadQuotes() -> AnyPublisher<Void, Never> {
        guard let currencyId = tokenItem.currencyId else {
            _rate.send(.custom)
            return .just(output: ())
        }

        return quotesRepository
            .loadQuotes(currencyIds: [currencyId])
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletModel, dict in
                walletModel.updateQuote(quote: dict[currencyId])
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    private func updateQuote(quote: TokenQuote?) {
        switch quote {
        // Don't have quote because we don't have currency id
        case .none where tokenItem.currencyId == nil:
            _rate.send(.custom)
        // Don't have quote because of error. Update with saving the previous one
        case .none:
            _rate.send(.failure(cached: rate.quote))
        case .some(let quote):
            _rate.send(.loaded(quote))
        }
    }

    // MARK: - Timer

    private func startUpdatingTimer() {
        walletManager.setNeedsUpdate()
        AppLogger.info(self, "⏰ Starting updating timer")
        updateTimer = Timer.TimerPublisher(
            interval: 10.0,
            tolerance: 0.1,
            runLoop: .main,
            mode: .common
        )
        .autoconnect()
        .withWeakCaptureOf(self)
        .flatMap { root, _ in
            AppLogger.info(root, "⏰ Updating timer alarm ‼️. WalletModel will be updated")
            return root.generalUpdate(silent: false)
        }
        .sink { [weak self] in
            self?.updateTimer?.cancel()
        }
    }
}

extension CommonWalletModel: Equatable {
    static func == (lhs: CommonWalletModel, rhs: CommonWalletModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - WalletModel

extension CommonWalletModel: WalletModel {
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> { featureManager.featuresPublisher }

    var name: String {
        switch amountType {
        case .coin, .reserve, .feeResource:
            return wallet.blockchain.displayName
        case .token(let token):
            return token.name
        }
    }

    var wallet: Wallet { walletManager.wallet }

    var addresses: [Address] { wallet.addresses }

    var defaultAddress: any Address { wallet.defaultAddress }

    var addressNames: [String] { wallet.addresses.map { $0.localizedName } }

    var isMainToken: Bool {
        switch amountType {
        case .coin, .reserve, .feeResource:
            return true
        case .token:
            return false
        }
    }

    var feeTokenItem: TokenItem {
        switch blockchainNetwork.blockchain.feePaidCurrency {
        case .coin:
            return .blockchain(blockchainNetwork)
        case .token(let value):
            return .token(value, blockchainNetwork)
        case .sameCurrency:
            return tokenItem
        case .feeResource(let type):
            // We use this when displaying the fee currency on the 'Send' screen.
            // This is because when sending KOIN, we use MANA as the fee.
            return .token(
                Token(
                    name: type.rawValue,
                    symbol: type.rawValue,
                    contractAddress: "",
                    decimalCount: 0
                ),
                blockchainNetwork
            )
        }
    }

    /// Quotes can't be fetched for custom tokens.
    var canUseQuotes: Bool { tokenItem.currencyId != nil }

    var quote: TokenQuote? { quotesRepository.quote(for: tokenItem) }

    var isEmpty: Bool { wallet.isEmpty }

    var publicKey: Wallet.PublicKey { wallet.publicKey }

    var shouldShowFeeSelector: Bool { walletManager.allowsFeeSelection }

    var defaultAddressString: String { wallet.defaultAddress.value }

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

    var actionsUpdatePublisher: AnyPublisher<Void, Never> {
        Publishers.Merge3(
            expressAvailabilityProvider.availabilityDidChangePublisher,
            stakingManagerStatePublisher.mapToVoid(),
            totalTokenBalanceProvider.balanceTypePublisher.mapToVoid()
        )
        .eraseToAnyPublisher()
    }

    var sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions? {
        sendAvailabilityProvider.sendingRestrictions(walletModel: self)
    }

    var isDemo: Bool { demoBalance != nil }

    var stakingManager: StakingManager? {
        _stakingManager
    }

    var stakeKitTransactionSender: StakeKitTransactionSender? {
        walletManager as? StakeKitTransactionSender
    }

    var accountInitializationStateProvider: (any StakingAccountInitializationStateProvider)? {
        walletManager as? StakingAccountInitializationStateProvider
    }
}

// MARK: - Updater

extension CommonWalletModel: WalletModelUpdater {
    /// Fire-and-forget — subscriptions are managed internally:
    /// `update()` in CommonWalletModel uses `updateWalletModelSubscription`,
    /// and `fetch()` in CommonTransactionHistoryService uses its own `cancellable`.
    func generalUpdate(silent: Bool) -> AnyPublisher<Void, Never> {
        _transactionHistoryService?.clearHistory()

        return Publishers
            .CombineLatest(update(silent: silent), updateTransactionsHistory())
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    /// Do not use with flatMap.
    func update(silent: Bool) -> AnyPublisher<WalletModelState, Never> {
        // If updating already in process return updating Publisher
        if let updatePublisher = updatePublisher {
            return updatePublisher.eraseToAnyPublisher()
        }

        // Keep this before the async call
        let newUpdatePublisher = PassthroughSubject<WalletModelState, Never>()
        updatePublisher = newUpdatePublisher

        if case .loading = state {
            return newUpdatePublisher.eraseToAnyPublisher()
        }

        if !silent {
            updateState(.loading)
        }

        updateWalletModelSubscription = walletManager
            .updatePublisher()
            .combineLatest(loadQuotes(), updateStakingManagerState())
            .withWeakCaptureOf(self)
            .sink { walletModel, newState in
                let newState = walletModel.walletManager.state
                walletModel.walletManagerDidUpdate(newState)

                walletModel.updatePublisher?.send(walletModel.mapState(newState))
                walletModel.updatePublisher?.send(completion: .finished)
                walletModel.updatePublisher = nil
            }

        return newUpdatePublisher.eraseToAnyPublisher()
    }

    func updateAfterSendingTransaction() {
        // Force update transactions history to take a new pending transaction from the local storage
        _localPendingTransactionSubject.send(())
        startUpdatingTimer()
    }

    func updateTransactionsHistory() -> AnyPublisher<Void, Never> {
        guard let _transactionHistoryService else {
            AppLogger.info(self, "TransactionsHistory not supported")
            return .just(output: ())
        }

        return _transactionHistoryService.update()
    }

    private func updateStakingManagerState() -> AnyPublisher<Void, Never> {
        Future.async { [weak self] in
            await self?._stakingManager?.updateState(loadActions: true)
        }
        // Here we have to skip the error to let the PTR to complete
        .replaceError(with: ())
        .eraseToAnyPublisher()
    }
}

// MARK: - Balance Provider

extension CommonWalletModel: WalletModelBalancesProvider {
    func makeAvailableBalanceProvider() -> TokenBalanceProvider {
        AvailableTokenBalanceProvider(
            input: self,
            walletModelId: id,
            tokenItem: tokenItem,
            tokenBalancesRepository: tokenBalancesRepository
        )
    }

    func makeStakingBalanceProvider() -> TokenBalanceProvider {
        StakingTokenBalanceProvider(
            input: self,
            walletModelId: id,
            tokenItem: tokenItem,
            tokenBalancesRepository: tokenBalancesRepository
        )
    }

    func makeTotalTokenBalanceProvider() -> TokenBalanceProvider {
        TotalTokenBalanceProvider(
            tokenItem: tokenItem,
            availableBalanceProvider: availableBalanceProvider,
            stakingBalanceProvider: stakingBalanceProvider
        )
    }

    func makeFiatAvailableBalanceProvider() -> TokenBalanceProvider {
        FiatTokenBalanceProvider(input: self, cryptoBalanceProvider: availableBalanceProvider)
    }

    func makeFiatStakingBalanceProvider() -> TokenBalanceProvider {
        FiatTokenBalanceProvider(input: self, cryptoBalanceProvider: stakingBalanceProvider)
    }

    func makeFiatTotalTokenBalanceProvider() -> TokenBalanceProvider {
        FiatTokenBalanceProvider(input: self, cryptoBalanceProvider: totalTokenBalanceProvider)
    }
}

// MARK: - Helpers

extension CommonWalletModel: WalletModelHelpers {
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

    /// A convenience wrapper for `AssetRequirementsManager.fulfillRequirements(for:signer:)`
    /// that automatically triggers the update of the internal state of this wallet model.
    func fulfillRequirements(signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        return assetRequirementsManager
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { walletModel, assetRequirementsManager in
                assetRequirementsManager.fulfillRequirements(for: walletModel.tokenItem.amountType, signer: signer)
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletModel, _ in
                walletModel.updateAfterSendingTransaction()
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}

// MARK: - Fee

extension CommonWalletModel: WalletModelFeeProvider {
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        return walletManager.estimatedFee(amount: amount)
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        if isDemo {
            let demoFees = DemoUtil().getDemoFee(for: walletManager.wallet.blockchain)
            return .justWithError(output: demoFees)
        }

        return walletManager.getFee(amount: amount, destination: destination)
    }

    func getFeeCurrencyBalance(amountType: Amount.AmountType) -> Decimal {
        wallet.feeCurrencyBalance(amountType: amountType)
    }

    func hasFeeCurrency(amountType: BlockchainSdk.Amount.AmountType) -> Bool {
        wallet.hasFeeCurrency(amountType: amountType)
    }
}

// MARK: - Dependencies

extension CommonWalletModel: WalletModelDependenciesProvider {
    var blockchainDataProvider: BlockchainDataProvider {
        walletManager
    }

    var transactionValidator: TransactionValidator {
        walletManager
    }

    var transactionCreator: TransactionCreator {
        walletManager
    }

    var transactionSender: TransactionSender {
        walletManager
    }

    var bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator? {
        walletManager as? BitcoinTransactionFeeCalculator
    }

    var ethereumTransactionSigner: EthereumTransactionSigner? {
        walletManager as? EthereumTransactionSigner
    }

    var ethereumNetworkProvider: EthereumNetworkProvider? {
        walletManager as? EthereumNetworkProvider
    }

    var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder? {
        walletManager as? EthereumTransactionDataBuilder
    }

    var withdrawalNotificationProvider: WithdrawalNotificationProvider? {
        walletManager as? WithdrawalNotificationProvider
    }

    var assetRequirementsManager: AssetRequirementsManager? {
        walletManager as? AssetRequirementsManager
    }
}

// MARK: - Transaction history

extension CommonWalletModel: WalletModelTransactionHistoryProvider {
    var isSupportedTransactionHistory: Bool {
        _transactionHistoryService != nil
    }

    /// Listen tx history changes
    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> {
        transactionHistoryState()
    }

    var hasPendingTransactions: Bool {
        // For bitcoin we check only outgoing transaction
        // because we will not use unconfirmed utxo
        if case .bitcoin = blockchainNetwork.blockchain {
            return wallet.pendingTransactions.contains { !$0.isIncoming }
        }

        return wallet.hasPendingTx(for: amountType)
    }

    var hasAnyPendingTransactions: Bool {
        // For bitcoin we check only outgoing transaction
        // because we will not use unconfirmed utxo
        if case .bitcoin = blockchainNetwork.blockchain {
            return wallet.pendingTransactions.contains { !$0.isIncoming }
        }

        return wallet.hasPendingTx
    }

    var pendingTransactionPublisher: AnyPublisher<[PendingTransactionRecord], Never> {
        walletManager
            .walletPublisher
            .withWeakCaptureOf(self)
            .map {
                $0.pendingTransaction(for: $1)
            }
            .eraseToAnyPublisher()
    }

    var isEmptyIncludingPendingIncomingTxs: Bool {
        let incomingPendingTxs = wallet.pendingTransactions.filter { $0.isIncoming && $0.amount.type == amountType }

        return wallet.isEmpty && incomingPendingTxs.isEmpty
    }

    private func pendingTransaction(for wallet: Wallet) -> [PendingTransactionRecord] {
        wallet.pendingTransactions.filter { !$0.isDummy && $0.amount.type == amountType }
    }

    private func transactionHistoryState() -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        guard let _transactionHistoryService else {
            return .just(output: .notSupported)
        }

        return Publishers.Merge(
            _localPendingTransactionSubject.withLatestFrom(_transactionHistoryService.statePublisher),
            _transactionHistoryService.statePublisher
        )
        .map { [weak self] state -> WalletModelTransactionHistoryState in
            switch state {
            case .initial:
                return .notLoaded
            case .loading:
                return .loading
            case .loaded:
                var items = self?._transactionHistoryService?.items ?? []
                self?.insertPendingTransactionRecordIfNeeded(into: &items)
                return .loaded(items: items)
            case .failedToLoad(let error):
                return .error(error)
            }
        }
        .eraseToAnyPublisher()
    }

    private func insertPendingTransactionRecordIfNeeded(into items: inout [TransactionRecord]) {
        let pendingTransactions = pendingTransaction(for: wallet)
        guard !pendingTransactions.isEmpty else {
            AppLogger.info(self, "has not local pending transactions")
            return
        }

        AppLogger.info(self, "has pending local transactions. Try to insert it to transaction history")
        let mapper = PendingTransactionRecordMapper(formatter: formatter)

        pendingTransactions.forEach { pending in
            if items.contains(where: { $0.hash == pending.hash }) {
                AppLogger.info(self, "Transaction history already contains pending transaction")
            } else {
                let record = mapper.mapToTransactionRecord(pending: pending)
                AppLogger.info(self, "Inserted to transaction history transaction")
                items.insert(record, at: 0)
            }
        }
    }
}

// MARK: - RentProvider

extension CommonWalletModel: WalletModelRentProvider {
    var hasRent: Bool {
        walletManager is RentProvider
    }

    func updateRentWarning() -> AnyPublisher<String?, Never> {
        guard let rentProvider = walletManager as? RentProvider else {
            return .just(output: nil)
        }

        return rentProvider.rentAmount()
            .zip(rentProvider.minimalBalanceForRentExemption())
            .receive(on: DispatchQueue.main)
            .map { [weak self] rentAmount, minimalBalanceForRentExemption in
                guard
                    let self = self,
                    let amount = wallet.amounts[.coin],
                    amount < minimalBalanceForRentExemption
                else {
                    return nil
                }

                return Localization.warningSolanaRentFeeMessage(rentAmount.description, minimalBalanceForRentExemption.description)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}

// MARK: - ExistentialDepositProvider

extension CommonWalletModel: ExistentialDepositInfoProvider {
    var existentialDeposit: Amount? {
        existentialDepositProvider?.existentialDeposit
    }

    var existentialDepositWarning: String? {
        guard let existentialDeposit = existentialDeposit else {
            return nil
        }

        let blockchainName = blockchainNetwork.blockchain.displayName
        let existentialDepositAmount = existentialDeposit.string(roundingMode: .plain)
        return Localization.warningExistentialDepositMessage(blockchainName, existentialDepositAmount)
    }

    private var existentialDepositProvider: ExistentialDepositProvider? {
        walletManager as? ExistentialDepositProvider
    }
}

// MARK: - Tx history fetcher

extension CommonWalletModel: TransactionHistoryFetcher {
    var canFetchHistory: Bool {
        _transactionHistoryService?.canFetchHistory ?? false
    }

    func clearHistory() {
        _transactionHistoryService?.clearHistory()
    }
}

// MARK: - AvailableTokenBalanceProviderInput

extension CommonWalletModel: AvailableTokenBalanceProviderInput {
    var state: WalletModelState {
        _state.value
    }

    var statePublisher: AnyPublisher<WalletModelState, Never> {
        _state.eraseToAnyPublisher()
    }
}

// MARK: - StakingTokenBalanceProviderInput

extension CommonWalletModel: StakingTokenBalanceProviderInput {
    var stakingManagerState: StakingManagerState {
        _stakingManager?.state ?? .notEnabled
    }

    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        _stakingManager.map { $0.statePublisher } ?? .just(output: .notEnabled)
    }
}

// MARK: - FiatTokenBalanceProviderInput

extension CommonWalletModel: FiatTokenBalanceProviderInput {
    var rate: WalletModelRate {
        _rate.value
    }

    var ratePublisher: AnyPublisher<WalletModelRate, Never> {
        _rate.eraseToAnyPublisher()
    }
}

extension CommonWalletModel: FeeResourceInfoProvider {
    var feeResourceBalance: Decimal? {
        switch tokenItem.blockchain {
        case .koinos:
            return wallet.amounts[.feeResource(.mana)]?.value
        default:
            return nil
        }
    }

    var maxResourceBalance: Decimal? {
        switch tokenItem.blockchain {
        case .koinos:
            return wallet.amounts[.coin]?.value
        default:
            return nil
        }
    }
}

// MARK: - WalletModelError

enum WalletModelError: LocalizedError {
    case balanceNotFound

    var errorDescription: String? {
        switch self {
        case .balanceNotFound: "Balance not found"
        }
    }
}
