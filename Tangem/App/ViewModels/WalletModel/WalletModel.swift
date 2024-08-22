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
import TangemStaking
import TangemFoundation

class WalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider
    @Injected(\.accountHealthChecker) private var accountHealthChecker: AccountHealthChecker

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

    var isSupportedTransactionHistory: Bool {
        _transactionHistoryService != nil
    }

    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        _stakingManager.map { $0.statePublisher } ?? .just(output: .notEnabled)
    }

    var stakingManagerState: StakingManagerState {
        _stakingManager?.state ?? .notEnabled
    }

    var shouldShowFeeSelector: Bool {
        walletManager.allowsFeeSelection
    }

    var tokenItem: TokenItem {
        switch amountType {
        case .coin, .reserve, .feeResource:
            return .blockchain(blockchainNetwork)
        case .token(let token):
            return .token(token, blockchainNetwork)
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

    var name: String {
        switch amountType {
        case .coin, .reserve, .feeResource:
            return wallet.blockchain.displayName
        case .token(let token):
            return token.name
        }
    }

    var isMainToken: Bool {
        switch amountType {
        case .coin, .reserve, .feeResource:
            return true
        case .token:
            return false
        }
    }

    var balanceValue: Decimal? {
        availableBalance.crypto
    }

    var balance: String {
        availableBalanceFormatted.crypto
    }

    var isZeroAmount: Bool {
        wallet.amounts[amountType]?.isZero ?? true
    }

    var fiatBalance: String {
        availableBalanceFormatted.fiat
    }

    var fiatValue: Decimal? {
        availableBalance.fiat
    }

    var rateFormatted: String {
        guard let rate = quote?.price else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return formatter.formatFiatBalance(rate, formattingOptions: .defaultFiatFormattingOptions)
    }

    /// Quotes can't be fetched for custom tokens.
    var canUseQuotes: Bool { tokenItem.currencyId != nil }

    var quote: TokenQuote? {
        quotesRepository.quote(for: tokenItem)
    }

    var hasPendingTransactions: Bool {
        wallet.hasPendingTx(for: amountType)
    }

    var wallet: Wallet { walletManager.wallet }

    var addresses: [String] {
        wallet.addresses.map { $0.value }
    }

    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }

    var defaultAddress: String {
        wallet.defaultAddress.value
    }

    var isTestnet: Bool {
        wallet.blockchain.isTestnet
    }

    var pendingTransactions: [PendingTransactionRecord] {
        wallet.pendingTransactions.filter { !$0.isDummy && $0.amount.type == amountType }
    }

    var incomingPendingTransactions: [PendingTransactionRecord] {
        wallet.pendingTransactions.filter { $0.isIncoming && $0.amount.type == amountType }
    }

    var outgoingPendingTransactions: [PendingTransactionRecord] {
        wallet.pendingTransactions.filter { !$0.isIncoming }
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

    var sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions? {
        TransactionSendAvailabilityProvider().sendingRestrictions(walletModel: self)
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> {
        Publishers.Merge(
            swapAvailabilityProvider.tokenItemsAvailableToSwapPublisher.mapToVoid(),
            stakingManagerStatePublisher.mapToVoid()
        )
        .eraseToAnyPublisher()
    }

    var isDemo: Bool { demoBalance != nil }
    var demoBalance: Decimal?

    let amountType: Amount.AmountType
    let isCustom: Bool

    private let walletManager: WalletManager
    private let _stakingManager: StakingManager?
    private let _transactionHistoryService: TransactionHistoryService?
    private var updateTimer: AnyCancellable?
    private var updateWalletModelSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()
    private var updatePublisher: PassthroughSubject<State, Never>?
    private var updateQueue = DispatchQueue(label: "walletModel_update_queue")
    private var _walletDidChangePublisher: CurrentValueSubject<State, Never> = .init(.created)
    private var _state: CurrentValueSubject<State, Never> = .init(.created)
    private var _rate: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private var _localPendingTransactionSubject: PassthroughSubject<Void, Never> = .init()

    private let converter = BalanceConverter()
    private let formatter = BalanceFormatter()

    deinit {
        AppLog.shared.debug("🗑 \(self) deinit")
    }

    init(
        walletManager: WalletManager,
        stakingManager: StakingManager?,
        transactionHistoryService: TransactionHistoryService?,
        amountType: Amount.AmountType,
        shouldPerformHealthCheck: Bool,
        isCustom: Bool
    ) {
        self.walletManager = walletManager
        _stakingManager = stakingManager
        _transactionHistoryService = transactionHistoryService
        self.amountType = amountType
        self.isCustom = isCustom

        bind()
        performHealthCheckIfNeeded(shouldPerform: shouldPerformHealthCheck)
    }

    func bind() {
        walletManager.statePublisher
            .filter { !$0.isInitialState }
            .receive(on: updateQueue)
            .sink { [weak self] newState in
                self?.walletManagerDidUpdate(newState)
            }
            .store(in: &bag)

        quotesRepository
            .quotesPublisher
            .compactMap { [canUseQuotes, tokenItem] quotes -> Decimal? in
                guard
                    canUseQuotes,
                    let currencyId = tokenItem.currencyId
                else {
                    return nil
                }

                return quotes[currencyId]?.price
            }
            .removeDuplicates()
            .sink { [weak self] rate in
                guard let self else { return }

                AppLog.shared.debug("🔄 Quotes updated for \(self)")
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

    private func performHealthCheckIfNeeded(shouldPerform: Bool) {
        if shouldPerform {
            accountHealthChecker.performAccountCheckIfNeeded(wallet.address)
        }
    }

    // MARK: - Update wallet model

    func generalUpdate(silent: Bool) -> AnyPublisher<Void, Never> {
        _transactionHistoryService?.clearHistory()

        return Publishers
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
            .combineLatest(loadQuotes(), updateStakingManagerState()) { state, _, _ in state }
            .receive(on: updateQueue)
            .sink { [weak self] newState in
                guard let self else { return }

                AppLog.shared.debug("🔄 Finished common update for \(self)")

                updatePublisher?.send(mapState(newState))
                updatePublisher?.send(completion: .finished)
                updatePublisher = nil
            }

        return newUpdatePublisher.eraseToAnyPublisher()
    }

    func updateAfterSendingTransaction() {
        // Force update transactions history to take a new pending transaction from the local storage
        _localPendingTransactionSubject.send(())
        startUpdatingTimer()
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
        case .failed(WalletError.noAccount(let message, let amountToCreate)):
            return .noAccount(message: message, amountToCreate: amountToCreate)
        case .failed(let error):
            return .failed(error: error.detailedError.localizedDescription)
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

    // MARK: - Load Quotes

    private func loadQuotes() -> AnyPublisher<Void, Never> {
        guard
            canUseQuotes,
            let currencyId = tokenItem.currencyId
        else {
            return .just(output: ())
        }

        AppLog.shared.debug("🔄 Start loading quotes for \(self)")

        return quotesRepository
            .loadQuotes(currencyIds: [currencyId])
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
        .withWeakCaptureOf(self)
        .flatMap { root, _ in
            AppLog.shared.debug("⏰ Updating timer alarm ‼️ \(String(describing: self)) will be updated")
            return root.generalUpdate(silent: false)
        }
        .sink { [weak self] in
            self?.updateTimer?.cancel()
        }
    }

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

    /// A convenience wrapper for `AssetRequirementsManager.fulfillRequirements(for:signer:)`
    /// that automatically triggers the update of the internal state of this wallet model.
    func fulfillRequirements(signer: any TransactionSigner) -> some Publisher<Void, Error> {
        return assetRequirementsManager
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { walletModel, assetRequirementsManager in
                assetRequirementsManager.fulfillRequirements(for: walletModel.amountType, signer: signer)
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletModel, _ in
                walletModel.updateAfterSendingTransaction()
            })
            .mapToVoid()
    }
}

// MARK: - Transaction history

extension WalletModel {
    func updateTransactionsHistory() -> AnyPublisher<Void, Never> {
        guard let _transactionHistoryService else {
            AppLog.shared.debug("TransactionsHistory for \(self) not supported")
            return .just(output: ())
        }

        AppLog.shared.debug("TransactionsHistory for \(self) start the updating")
        return _transactionHistoryService.update()
    }

    private func transactionHistoryState() -> AnyPublisher<WalletModel.TransactionHistoryState, Never> {
        guard let _transactionHistoryService else {
            return .just(output: .notSupported)
        }

        return Publishers.Merge(
            _localPendingTransactionSubject.withLatestFrom(_transactionHistoryService.statePublisher),
            _transactionHistoryService.statePublisher
        )
        .map { [weak self] state -> WalletModel.TransactionHistoryState in
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
        guard !pendingTransactions.isEmpty else {
            AppLog.shared.debug("\(self) has not local pending transactions")
            return
        }

        AppLog.shared.debug("\(self) has pending local transactions \(pendingTransactions.map { $0.hash }). Try to insert it to transaction history")
        let mapper = PendingTransactionRecordMapper(formatter: formatter)

        pendingTransactions.forEach { pending in
            if items.contains(where: { $0.hash == pending.hash }) {
                AppLog.shared.debug("\(self) Transaction history already contains \(pending.hash)")
            } else {
                let record = mapper.mapToTransactionRecord(pending: pending)
                AppLog.shared.debug("\(self) Inserted to transaction history \(record.hash)")
                items.insert(record, at: 0)
            }
        }
    }
}

// MARK: - ExistentialDepositProvider

extension WalletModel {
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
}

// MARK: - RentProvider

extension WalletModel {
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

// MARK: - Staking

extension WalletModel {
    func updateStakingManagerState() -> AnyPublisher<Void, Never> {
        Future.async { [weak self] in
            try await self?._stakingManager?.updateState()
        }
        // Here we have to skip the error to let the PTR to complete
        .replaceError(with: ())
        .eraseToAnyPublisher()
    }
}

// MARK: - Interfaces

extension WalletModel {
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

    var transactionPusher: TransactionPusher? {
        walletManager as? TransactionPusher
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

    var signatureCountValidator: SignatureCountValidator? {
        walletManager as? SignatureCountValidator
    }

    var addressResolver: AddressResolver? {
        walletManager as? AddressResolver
    }

    var withdrawalNotificationProvider: WithdrawalNotificationProvider? {
        walletManager as? WithdrawalNotificationProvider
    }

    var hasRent: Bool {
        walletManager is RentProvider
    }

    var existentialDepositProvider: ExistentialDepositProvider? {
        walletManager as? ExistentialDepositProvider
    }

    var assetRequirementsManager: AssetRequirementsManager? {
        walletManager as? AssetRequirementsManager
    }

    var stakingManager: StakingManager? {
        _stakingManager
    }

    var stakeKitTransactionSender: StakeKitTransactionSender? {
        walletManager as? StakeKitTransactionSender
    }
}

extension WalletModel: TransactionHistoryFetcher {
    var canFetchHistory: Bool {
        _transactionHistoryService?.canFetchHistory ?? false
    }

    func clearHistory() {
        _transactionHistoryService?.clearHistory()
    }
}

// MARK: - Balance

extension WalletModel {
    typealias Balance = (crypto: Decimal?, fiat: Decimal?)
    typealias BalanceFormatted = (crypto: String, fiat: String)

    var allBalance: Balance {
        let cryptoBalance: Decimal? = {
            switch (availableBalance.crypto, stakingManager?.state.blockedBalance) {
            case (.none, _): nil
            // What we have to do if we have only blocked balance?
            case (.some(let available), .none): available
            case (.some(let available), .some(let blocked)): available + blocked
            }
        }()

        let fiatBalance: Decimal? = {
            guard let cryptoBalance, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(cryptoBalance, currencyId: currencyId)
        }()

        return (crypto: cryptoBalance, fiat: fiatBalance)
    }

    var availableBalance: Balance {
        let cryptoBalance: Decimal? = {
            if state.isNoAccount {
                return 0
            }

            return wallet.amounts[amountType]?.value
        }()

        let fiatBalance: Decimal? = {
            guard let cryptoBalance, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(cryptoBalance, currencyId: currencyId)
        }()

        return (crypto: cryptoBalance, fiat: fiatBalance)
    }

    var stakedBalance: Balance {
        let stakingBalance = stakingManagerState.blockedBalance
        let fiatBalance: Decimal? = {
            guard let stakingBalance, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(stakingBalance, currencyId: currencyId)
        }()

        return (crypto: stakingBalance, fiat: fiatBalance)
    }

    var stakedRewardsBalance: Balance {
        let rewardsToClaim = stakingManagerState.rewardsToClaim
        let fiatBalance: Decimal? = {
            guard let rewardsToClaim, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(rewardsToClaim, currencyId: currencyId)
        }()

        return (crypto: rewardsToClaim, fiat: fiatBalance)
    }

    var allBalanceFormatted: BalanceFormatted {
        formatted(allBalance)
    }

    var stakedBalanceFormatted: BalanceFormatted {
        formatted(stakedBalance)
    }

    var availableBalanceFormatted: BalanceFormatted {
        formatted(availableBalance)
    }

    var stakedRewardsBalanceFormatted: BalanceFormatted {
        formatted(stakedRewardsBalance)
    }

    private func formatted(_ balance: Balance) -> BalanceFormatted {
        let cryptoFormatted = formatter.formatCryptoBalance(balance.crypto, currencyCode: tokenItem.currencySymbol)
        let fiatFormatted = formatter.formatFiatBalance(balance.fiat)

        return (crypto: cryptoFormatted, fiat: fiatFormatted)
    }
}

private extension StakingManagerState {
    var blockedBalance: Decimal? {
        guard case .staked(let staked) = self else {
            return nil
        }

        return staked.balances.staking().sum()
    }

    var rewardsToClaim: Decimal? {
        guard case .staked(let staked) = self else {
            return nil
        }

        return staked.balances.rewards().sum()
    }
}
