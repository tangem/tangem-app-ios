//
//  VisaWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemVisa
import TangemStaking
import TangemExpress
import TangemLocalization

class VisaWalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider
    let id: WalletModelId

    lazy var availableBalanceProvider = makeAvailableBalanceProvider()
    let stakingBalanceProvider: TokenBalanceProvider = NotSupportedStakingTokenBalanceProvider()
    lazy var totalTokenBalanceProvider = makeTotalTokenBalanceProvider()

    lazy var fiatAvailableBalanceProvider = makeFiatAvailableBalanceProvider()
    lazy var fiatStakingBalanceProvider = makeFiatStakingBalanceProvider()
    lazy var fiatTotalTokenBalanceProvider = makeFiatTotalTokenBalanceProvider()

    var demoBalance: Decimal?
    let tokenItem: TokenItem
    private let stateSubject = CurrentValueSubject<WalletModelState, Never>(.created)
    private lazy var rateSubject = CurrentValueSubject<WalletModelRate, Never>(.loading(cached: quotesRepository.quote(for: tokenItem)))
    private let transactionDependency = VisaDummyTransactionDependencies(isTestnet: FeatureStorage.instance.isVisaTestnet)
    private let tokenBalancesRepository: TokenBalancesRepository
    private let transactionSendAvailabilityProvider: TransactionSendAvailabilityProvider

    init(
        tokenItem: TokenItem,
        tokenBalancesRepository: TokenBalancesRepository,
        transactionSendAvailabilityProvider: TransactionSendAvailabilityProvider
    ) {
        self.tokenItem = tokenItem
        id = .init(tokenItem: tokenItem)

        self.tokenBalancesRepository = tokenBalancesRepository
        self.transactionSendAvailabilityProvider = transactionSendAvailabilityProvider
    }
}

extension VisaWalletModel: WalletModelUpdater {
    func generalUpdate(silent: Bool) -> AnyPublisher<Void, Never> {
        // [REDACTED_TODO_COMMENT]
        return Just(()).eraseToAnyPublisher()
    }

    func update(silent: Bool) -> AnyPublisher<WalletModelState, Never> {
        // [REDACTED_TODO_COMMENT]
        return stateSubject.eraseToAnyPublisher()
    }

    func updateTransactionsHistory() -> AnyPublisher<Void, Never> {
        // [REDACTED_TODO_COMMENT]
        return Just(()).eraseToAnyPublisher()
    }

    func updateAfterSendingTransaction() {
        // [REDACTED_TODO_COMMENT]
    }
}

extension VisaWalletModel: WalletModelBalancesProvider {
    func makeAvailableBalanceProvider() -> TokenBalanceProvider {
        AvailableTokenBalanceProvider(
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

extension VisaWalletModel: AvailableTokenBalanceProviderInput {
    var state: WalletModelState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<WalletModelState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
}

extension VisaWalletModel: StakingTokenBalanceProviderInput {
    var stakingManagerState: StakingManagerState {
        .notEnabled
    }

    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        Just(.notEnabled).eraseToAnyPublisher()
    }
}

extension VisaWalletModel: FiatTokenBalanceProviderInput {
    var rate: WalletModelRate {
        rateSubject.value
    }

    var ratePublisher: AnyPublisher<WalletModelRate, Never> {
        rateSubject.eraseToAnyPublisher()
    }
}

extension VisaWalletModel: WalletModelHelpers {
    func displayAddress(for index: Int) -> String {
        // [REDACTED_TODO_COMMENT]
        return ""
    }

    func shareAddressString(for index: Int) -> String {
        // [REDACTED_TODO_COMMENT]
        return ""
    }

    func exploreURL(for index: Int, token: Token?) -> URL? {
        // [REDACTED_TODO_COMMENT]
        return nil
    }

    func exploreTransactionURL(for hash: String) -> URL? {
        // [REDACTED_TODO_COMMENT]
        return nil
    }

    func fulfillRequirements(signer: any TransactionSigner) -> AnyPublisher<Void, any Error> {
        return .justWithError(output: ())
    }
}

extension VisaWalletModel: WalletModelFeeProvider {
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], any Error> {
        return .justWithError(output: [])
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        return .justWithError(output: [])
    }

    func hasFeeCurrency(amountType: Amount.AmountType) -> Bool {
        return false
    }
}

extension VisaWalletModel: WalletModelDependenciesProvider {
    var blockchainDataProvider: any BlockchainDataProvider { VisaDummyBlockchainDataProvider() }
    var withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? { nil }
    var assetRequirementsManager: (any AssetRequirementsManager)? { nil }
    var addressResolver: (any AddressResolver)? { nil }
    var transactionCreator: any TransactionCreator { transactionDependency }
    var transactionValidator: any TransactionValidator { transactionDependency }
    var transactionSender: any TransactionSender { transactionDependency }
    var ethereumTransactionDataBuilder: (any EthereumTransactionDataBuilder)? { nil }
    var ethereumNetworkProvider: (any EthereumNetworkProvider)? { nil }
    var ethereumTransactionSigner: (any EthereumTransactionSigner)? { nil }
    var bitcoinTransactionFeeCalculator: (any BitcoinTransactionFeeCalculator)? { nil }
}

extension VisaWalletModel: WalletModelTransactionHistoryProvider {
    var isSupportedTransactionHistory: Bool {
        false
    }

    var hasPendingTransactions: Bool {
        false
    }

    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> {
        .just(output: .notSupported)
    }

    var pendingTransactionPublisher: AnyPublisher<[PendingTransactionRecord], Never> {
        .just(output: [])
    }

    var isEmptyIncludingPendingIncomingTxs: Bool {
        true
    }
}

extension VisaWalletModel: WalletModelRentProvider {
    var hasRent: Bool { false }
    func updateRentWarning() -> AnyPublisher<String?, Never> { .just(output: nil) }
}

extension VisaWalletModel: TransactionHistoryFetcher {
    var canFetchHistory: Bool { false }
    func clearHistory() {}
}

extension VisaWalletModel: ExpressWallet {
    var expressCurrency: ExpressCurrency { tokenItem.expressCurrency }
    var defaultAddressString: String { defaultAddress.value }
    var decimalCount: Int { tokenItem.decimalCount }
    var feeCurrencyDecimalCount: Int { tokenItem.blockchain.decimalCount }
    var isFeeCurrency: Bool { false }

    func getBalance() throws -> Decimal {
        // Will be supported later
        throw "Not implemented"
    }

    func getFeeCurrencyBalance() -> Decimal { return 0 }
}

extension VisaWalletModel: ExistentialDepositInfoProvider {
    var existentialDepositWarning: String? {
        nil
    }
}

extension VisaWalletModel: WalletModel {
    var name: String {
        tokenItem.name
    }

    var addresses: [any Address] {
        // [REDACTED_TODO_COMMENT]
        []
    }

    var defaultAddress: any Address {
        // [REDACTED_TODO_COMMENT]
        PlainAddress(value: "", publicKey: publicKey, type: .default)
    }

    var addressNames: [String] {
        []
    }

    var isMainToken: Bool {
        true
    }

    var feeTokenItem: TokenItem {
        TokenItem.blockchain(tokenItem.blockchainNetwork)
    }

    var canUseQuotes: Bool {
        true
    }

    var quote: TokenQuote? {
        quotesRepository.quote(for: tokenItem)
    }

    var isEmpty: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    var publicKey: Wallet.PublicKey {
        .init(seedKey: Data(), derivationType: nil)
    }

    var shouldShowFeeSelector: Bool {
        false
    }

    var isCustom: Bool {
        false
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> {
        expressAvailabilityProvider.availabilityDidChangePublisher
    }

    var qrReceiveMessage: String {
        Localization.addressQrCodeMessageFormat(tokenItem.name, tokenItem.currencySymbol, tokenItem.blockchain.displayName)
    }

    var balanceState: WalletModelBalanceState? {
        // [REDACTED_TODO_COMMENT]
        nil
    }

    var isDemo: Bool {
        false
    }

    var sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions? {
        transactionSendAvailabilityProvider.sendingRestrictions(walletModel: self)
    }

    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        .just(output: [])
    }

    var stakingManager: (any StakingManager)? { nil }

    var stakeKitTransactionSender: (any StakeKitTransactionSender)? { nil }

    var accountInitializationStateProvider: (any StakingAccountInitializationStateProvider)? { nil }
}

extension VisaWalletModel: Equatable {
    static func == (lhs: VisaWalletModel, rhs: VisaWalletModel) -> Bool {
        return lhs.id == rhs.id
    }
}
