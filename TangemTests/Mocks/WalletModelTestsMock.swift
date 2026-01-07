//
//  MockWalletModel.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
@testable import Tangem
@testable import BlockchainSdk
@testable import TangemStaking

final class WalletModelTestsMock: WalletModel {
    private let _fiatBalance: Decimal
    private let _priceChange24h: Decimal?
    private let _fiatBalanceProvider: TokenBalanceProvider

    init(fiatBalance: Decimal, priceChange24h: Decimal?) {
        _fiatBalance = fiatBalance
        _priceChange24h = priceChange24h
        _fiatBalanceProvider = TokenBalanceProviderTestsMock(balance: fiatBalance)
    }

    init(fiatBalanceProvider: TokenBalanceProvider, priceChange24h: Decimal?) {
        _fiatBalance = 0
        _priceChange24h = priceChange24h
        _fiatBalanceProvider = fiatBalanceProvider
    }

    var quote: TokenQuote? {
        guard let priceChange24h = _priceChange24h else { return nil }
        return TokenQuote(
            currencyId: "mock",
            price: 1,
            priceChange24h: priceChange24h,
            priceChange7d: nil,
            priceChange30d: nil,
            currencyCode: "USD"
        )
    }

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider {
        _fiatBalanceProvider
    }

    func updateFiatBalance(_ newState: TokenBalanceType) {
        if let mutableProvider = _fiatBalanceProvider as? MutableTokenBalanceProviderMock {
            mutableProvider.updateBalance(newState)
        }
    }

    // MARK: - AvailableTokenBalanceProviderInput

    var state: WalletModelState { .loaded(0) }
    var statePublisher: AnyPublisher<WalletModelState, Never> { Just(state).eraseToAnyPublisher() }

    // MARK: - FiatTokenBalanceProviderInput

    var rate: WalletModelRate {
        if let quote = quote {
            return .loaded(quote: quote)
        } else {
            return .custom
        }
    }

    var ratePublisher: AnyPublisher<WalletModelRate, Never> { Just(rate).eraseToAnyPublisher() }

    // MARK: - StakingTokenBalanceProviderInput

    var stakingManagerState: StakingManagerState { .notEnabled }
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> { Just(stakingManagerState).eraseToAnyPublisher() }

    // MARK: - ReceiveAddressTypesProvider

    var receiveAddressTypes: [ReceiveAddressType] { [] }
    var receiveAddressInfos: [ReceiveAddressInfo] { [] }

    // MARK: - WalletModelResolvable

    func resolve<R>(using resolver: R) -> R.Result where R: WalletModelResolving {
        fatalError("resolve(using:) not implemented for MockWalletModel")
    }

    // MARK: - WalletModelUpdater

    func update(silent: Bool, features: [WalletModelUpdaterFeatureType]) async {}

    func updateTransactionsHistory() async {}

    func updateAfterSendingTransaction() {}

    // MARK: - WalletModelRentProvider

    func updateRentWarning() -> AnyPublisher<String?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    // MARK: - WalletModelFeesProvider

    var tokenFeeLoader: any TokenFeeLoader { TokenFeeLoaderMock() }
    var tokenFeeProvider: any TokenFeeProvider { TokenFeeProviderMock() }
    var customFeeProvider: (any FeeSelectorCustomFeeProvider)? { .none }

    // MARK: - TransactionHistoryFetcher

    var canFetchHistory: Bool { false }

    func clearHistory() {}

    // MARK: - WalletModel Protocol Stubs

    var id: WalletModelId {
        WalletModelId(tokenItem: .blockchain(.init(.alephium(testnet: false), derivationPath: nil)))
    }

    var userWalletId: UserWalletId { UserWalletId(value: Data()) }
    var name: String { "Mock" }
    var addresses: [Address] { [defaultAddress] }
    var defaultAddress: Address {
        PlainAddress(value: "mock", publicKey: publicKey, type: .default)
    }

    var addressNames: [String] { [] }
    var isMainToken: Bool { true }
    var tokenItem: TokenItem { .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil)) }
    var feeTokenItem: TokenItem { tokenItem }
    var canUseQuotes: Bool { true }
    var isEmpty: Bool { false }
    var publicKey: Wallet.PublicKey { .init(seedKey: Data(), derivationType: nil) }
    var shouldShowFeeSelector: Bool { false }
    var isCustom: Bool { false }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var isAssetRequirementsTaskInProgressPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }
    var qrReceiveMessage: String { "" }
    var balanceState: WalletModelBalanceState? { nil }
    var isDemo: Bool { false }
    var demoBalance: Decimal? { get { nil } set {} }
    var sendingRestrictions: SendingRestrictions? { nil }
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> { Empty().eraseToAnyPublisher() }
    var stakingManager: StakingManager? { nil }
    var stakeKitTransactionSender: StakeKitTransactionSender? { nil }
    var p2pTransactionSender: (any P2PTransactionSender)? { nil }
    var account: (any CryptoAccountModel)? { nil }
    var yieldModuleManager: YieldModuleManager? { nil }
    var availableBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var stakingBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var totalTokenBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var fiatStakingBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var blockchainDataProvider: BlockchainDataProvider { fatalError() }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { nil }
    var assetRequirementsManager: AssetRequirementsManager? { nil }
    var transactionCreator: TransactionCreator { fatalError() }
    var transactionValidator: TransactionValidator { fatalError() }
    var transactionSender: TransactionSender { fatalError() }
    var multipleTransactionsSender: MultipleTransactionsSender? { nil }
    var compiledTransactionSender: CompiledTransactionSender? { nil }
    var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder? { nil }
    var ethereumNetworkProvider: EthereumNetworkProvider? { nil }
    var ethereumTransactionSigner: EthereumTransactionSigner? { nil }
    var bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator? { nil }
    var accountInitializationService: BlockchainAccountInitializationService? { nil }
    var minimalBalanceProvider: MinimalBalanceProvider? { nil }
    var isSupportedTransactionHistory: Bool { false }
    var hasPendingTransactions: Bool { false }
    var hasAnyPendingTransactions: Bool { false }
    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> { Empty().eraseToAnyPublisher() }
    var pendingTransactionPublisher: AnyPublisher<[PendingTransactionRecord], Never> { Empty().eraseToAnyPublisher() }
    var isEmptyIncludingPendingIncomingTxs: Bool { false }
    var hasRent: Bool { false }
    var existentialDepositWarning: String? { nil }

    // MARK: - CustomStringConvertible

    var description: String { "WalletModelTestsMock" }

    func displayAddress(for index: Int) -> String { "" }
    func shareAddressString(for index: Int) -> String { "" }
    func exploreURL(for index: Int, token: Token?) -> URL? { nil }
    func exploreTransactionURL(for hash: String) -> URL? { nil }
    func fulfillRequirements(signer: any TransactionSigner) -> AnyPublisher<Void, Error> { Empty().eraseToAnyPublisher() }
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> { Empty().eraseToAnyPublisher() }
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> { Empty().eraseToAnyPublisher() }
    func getFeeCurrencyBalance() -> Decimal { 0 }
    func hasFeeCurrency() -> Bool { false }
    func getFee(compiledTransaction data: Data) async throws -> [Fee] { [] }
    func hash(into hasher: inout Hasher) {}
    static func == (lhs: WalletModelTestsMock, rhs: WalletModelTestsMock) -> Bool { false }
}
