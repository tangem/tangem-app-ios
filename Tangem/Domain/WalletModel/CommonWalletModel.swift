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
import TangemSdk

class CommonWalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    let id: WalletModelId
    let userWalletId: UserWalletId
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

    private(set) weak var account: (any CryptoAccountModel)?

    private let sendAvailabilityProvider: TransactionSendAvailabilityProvider
    private let tokenBalancesRepository: TokenBalancesRepository
    private let walletManager: WalletManager
    private let _stakingManager: StakingManager?
    private lazy var _yieldModuleManager = makeYieldModuleManager()
    private let _transactionHistoryService: TransactionHistoryService?
    private let _receiveAddressService: ReceiveAddressService
    private let featureManager: WalletModelFeaturesManager

    private var assetRequirementsTaskCancellable: AnyCancellable?
    private let isAssetRequirementsTaskInProgressSubject: CurrentValueSubject<Bool, Never> = .init(false)

    private let _state: CurrentValueSubject<WalletModelState, Never> = .init(.created)
    private lazy var _rate: CurrentValueSubject<WalletModelRate, Never> = .init(.loading(cached: quotesRepository.quote(for: tokenItem)))

    private let _localPendingTransactionSubject: PassthroughSubject<Void, Never> = .init()
    private lazy var formatter = BalanceFormatter()

    private var bag = Set<AnyCancellable>()

    private var amountType: Amount.AmountType {
        tokenItem.amountType
    }

    private var blockchainNetwork: BlockchainNetwork {
        tokenItem.blockchainNetwork
    }

    var isAssetRequirementsTaskInProgressPublisher: AnyPublisher<Bool, Never> {
        isAssetRequirementsTaskInProgressSubject.eraseToAnyPublisher()
    }

    init(
        userWalletId: UserWalletId,
        tokenItem: TokenItem,
        walletManager: WalletManager,
        stakingManager: StakingManager?,
        featureManager: WalletModelFeaturesManager,
        transactionHistoryService: TransactionHistoryService?,
        receiveAddressService: ReceiveAddressService,
        sendAvailabilityProvider: TransactionSendAvailabilityProvider,
        tokenBalancesRepository: TokenBalancesRepository,
        isCustom: Bool
    ) {
        self.userWalletId = userWalletId
        self.walletManager = walletManager
        self.featureManager = featureManager
        _stakingManager = stakingManager
        _transactionHistoryService = transactionHistoryService
        _receiveAddressService = receiveAddressService
        self.tokenItem = tokenItem
        self.isCustom = isCustom
        self.sendAvailabilityProvider = sendAvailabilityProvider
        self.tokenBalancesRepository = tokenBalancesRepository

        id = WalletModelId(tokenItem: tokenItem)

        bind()
    }

    deinit {
        AppLogger.debug(self)
    }

    func setCryptoAccount(_ cryptoAccount: any CryptoAccountModel) {
        account = cryptoAccount
    }

    private func bind() {
        AppSettings.shared.$selectedCurrencyCode
            // Ignore already the selected code
            .dropFirst()
            // Ignore if the selected code is equal
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] _ in
                // Invoke immediate fiat update when currency changes (e.g. offline case)
                self?._rate.send(.loading(cached: nil))
            })
            .withWeakCaptureOf(self)
            // Reload existing quotes for a new currency code
            .asyncMap { model, _ in
                await model.loadQuotes()
            }
            .sink { _ in }
            .store(in: &bag)

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

    // MARK: - State updates

    @MainActor
    private func walletManagerDidUpdate() {
        switch walletManager.state {
        case .initial:
            updateState(.created)
        case .loading:
            updateState(.loading)
        case .failed(BlockchainSdkError.noAccount(let message, let amountToCreate)):
            updateState(.noAccount(message: message, amountToCreate: amountToCreate))
        case .failed(let error):
            updateState(.failed(error: error.toUniversalError().localizedDescription))
        case .loaded:
            addDemoBalanceIfNeeded()

            if let balance = wallet.amounts[amountType]?.value {
                updateState(.loaded(balance))
            } else {
                updateState(.failed(error: WalletModelError.balanceNotFound.localizedDescription))
            }
        }
    }

    @MainActor
    private func updateState(_ state: WalletModelState) {
        AppLogger.info(self, "Updating state. New state is \(state)")
        _yieldModuleManager?.updateState(walletModelState: state, balance: wallet.amounts[amountType])
        _state.value = state
    }

    private func addDemoBalanceIfNeeded() {
        if let demoBalance {
            walletManager.wallet.add(coinValue: demoBalance)
        }
    }

    // MARK: - Quotes

    private func loadQuotes() async {
        guard let currencyId = tokenItem.currencyId else {
            _rate.send(.custom)
            return
        }

        let quotes = await quotesRepository.loadQuotes(currencyIds: [currencyId])
        updateQuote(quote: quotes[currencyId])
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
            _rate.send(.loaded(quote: quote))
        }
    }

    // MARK: - Timer

    private func startUpdatingTimer() {
        Task { [weak self] in
            AppLogger.info(self, "⏰ Starting updating timer")
            try await Task.sleep(for: .seconds(10))

            AppLogger.info(self, "⏰ Updating timer alarm ‼️. WalletModel will be updated")
            self?.walletManager.setNeedsUpdate()
            await self?.update(silent: false, features: .full)
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
        Publishers.Merge4(
            expressAvailabilityProvider.availabilityDidChangePublisher,
            stakingManagerStatePublisher.mapToVoid(),
            totalTokenBalanceProvider.balanceTypePublisher.mapToVoid(),
            (yieldModuleManager?.statePublisher ?? Just(.none).eraseToAnyPublisher()).mapToVoid()
        )
        .eraseToAnyPublisher()
    }

    var sendingRestrictions: SendingRestrictions? {
        sendAvailabilityProvider.sendingRestrictions(walletModel: self)
    }

    var isDemo: Bool { demoBalance != nil }

    var stakingManager: StakingManager? {
        _stakingManager
    }

    var yieldModuleManager: (any YieldModuleManager)? {
        _yieldModuleManager
    }

    var stakeKitTransactionSender: StakeKitTransactionSender? {
        walletManager as? StakeKitTransactionSender
    }

    var p2pTransactionSender: P2PTransactionSender? {
        walletManager as? P2PTransactionSender
    }

    var accountInitializationService: (any BlockchainAccountInitializationService)? {
        walletManager as? BlockchainAccountInitializationService
    }

    var minimalBalanceProvider: (any MinimalBalanceProvider)? {
        walletManager as? MinimalBalanceProvider
    }
}

// MARK: - WalletModelUpdater

extension CommonWalletModel: WalletModelUpdater {
    func update(silent: Bool, features: [WalletModelUpdaterFeatureType]) async {
        let logger = AppLogger.tag("WalletModelUpdater")

        async let balancesUpdate: () = {
            if features.contains(.balances) {
                if !silent { await updateState(.loading) }

                async let update: () = walletManager.update()
                async let quotes: () = loadQuotes()
                async let staking: ()? = _stakingManager?.updateState(loadActions: true)

                _ = await (update, quotes, staking)
                logger.debug(self, "WalletModel did updated \(walletManager.state)")

                // There must be a delayed call, as we are waiting for the wallet manager update. Workflow for blockchains like Hedera
                await _receiveAddressService.update(with: addresses)
                logger.debug(self, "ReceiveAddressService did updated")

                await walletManagerDidUpdate()
                logger.debug(self, "Update method did ended \(walletManager.state)")
            }
        }()

        async let transactionHistoryUpdate: () = {
            if features.contains(.transactionHistory) {
                _transactionHistoryService?.clearHistory()
                logger.debug(self, "Clear transaction history")

                await updateTransactionsHistory()
                logger.debug(self, "Transaction history did updated")
            }
        }()

        // Keep parallel updating
        _ = await (balancesUpdate, transactionHistoryUpdate)
    }

    func updateAfterSendingTransaction() {
        // Force update transactions history to take a new pending transaction from the local storage
        _localPendingTransactionSubject.send(())
        startUpdatingTimer()
    }

    func updateTransactionsHistory() async {
        guard let _transactionHistoryService else {
            AppLogger.info(self, "TransactionsHistory not supported")
            return
        }

        try? await _transactionHistoryService.update().async()
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
        let subject = PassthroughSubject<Void, Error>()
        isAssetRequirementsTaskInProgressSubject.send(true)

        assetRequirementsTaskCancellable?.cancel()
        assetRequirementsTaskCancellable = assetRequirementsManager
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { walletModel, assetRequirementsManager in
                assetRequirementsManager.fulfillRequirements(for: walletModel.tokenItem.amountType, signer: signer)
            }
            .receive(on: DispatchQueue.main)
            .mapToVoid()
            .sink(
                receiveCompletion: { [weak self] completion in
                    subject.send(completion: completion)

                    if case .failure = completion {
                        self?.isAssetRequirementsTaskInProgressSubject.send(false)
                    }
                },
                receiveValue: { [weak self] in
                    self?.updateAfterSendingTransaction()
                }
            )

        return subject.eraseToAnyPublisher()
    }

    func makeYieldModuleManager() -> (YieldModuleManager & YieldModuleManagerUpdater)? {
        guard case .token(let token, _) = tokenItem,
              let yieldSupplyService = walletManager.yieldSupplyService,
              let ethereumNetworkProvider
        else {
            return nil
        }

        let nonFilteredPendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> =
            walletManager
                .walletPublisher
                .map { $0.pendingTransactions }
                .eraseToAnyPublisher()

        let yieldModuleStateRepository = CommonYieldModuleStateRepository(
            walletModelId: WalletModelId(tokenItem: tokenItem),
            userWalletId: userWalletId,
            token: token
        )

        return CommonYieldModuleManager(
            walletAddress: wallet.defaultAddress.value,
            userWalletId: userWalletId.stringValue,
            token: token,
            blockchain: wallet.blockchain,
            yieldSupplyService: yieldSupplyService,
            tokenBalanceProvider: totalTokenBalanceProvider,
            ethereumNetworkProvider: ethereumNetworkProvider,
            transactionCreator: transactionCreator,
            blockaidApiService: BlockaidFactory().makeBlockaidAPIService(),
            yieldModuleStateRepository: yieldModuleStateRepository,
            yieldModuleMarketsRepository: CommonYieldModuleMarketsRepository(),
            pendingTransactionsPublisher: nonFilteredPendingTransactionsPublisher,
            scheduleWalletUpdate: { [weak self] in
                self?.startUpdatingTimer()
            }
        )
    }
}

// MARK: - WalletModelFeesProvider

extension CommonWalletModel: WalletModelFeesProvider {
    var tokenFeeLoader: any TokenFeeLoader {
        TokenFeeLoaderBuilder().makeTokenFeeLoader(walletModel: self, walletManager: walletManager)
    }

    var customFeeProvider: (any FeeSelectorCustomFeeProvider)? {
        CustomFeeServiceFactory(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
        )
        .makeService()
    }
}

// MARK: - WalletModelFeeProvider

extension CommonWalletModel: WalletModelFeeProvider {
    func getFeeCurrencyBalance() -> Decimal {
        wallet.feeCurrencyBalance(amountType: tokenItem.amountType)
    }

    func hasFeeCurrency() -> Bool {
        wallet.hasFeeCurrency(amountType: tokenItem.amountType)
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

    var multipleTransactionsSender: (any MultipleTransactionsSender)? {
        walletManager as? (any MultipleTransactionsSender)
    }

    var compiledTransactionFeeProvider: CompiledTransactionFeeProvider? {
        walletManager as? CompiledTransactionFeeProvider
    }

    var compiledTransactionSender: CompiledTransactionSender? {
        walletManager as? CompiledTransactionSender
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

// MARK: - WalletModelReceiveAddressProvider

extension CommonWalletModel: ReceiveAddressTypesProvider {
    var receiveAddressTypes: [ReceiveAddressType] {
        _receiveAddressService.addressTypes
    }

    var receiveAddressInfos: [ReceiveAddressInfo] {
        _receiveAddressService.addressInfos
    }
}

// MARK: - WalletModelResolvable protocol conformance

extension CommonWalletModel: WalletModelResolvable {
    func resolve<R>(using resolver: R) -> R.Result where R: WalletModelResolving {
        resolver.resolve(walletModel: self)
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
