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
    private let _tokenItem: TokenItem
    private let _id: WalletModelId
    private let _isEmpty: Bool
    private let _fiatAvailableBalance: Decimal
    private let _account: (any CryptoAccountModel)?

    init(fiatBalance: Decimal, priceChange24h: Decimal?) {
        _fiatBalance = fiatBalance
        _priceChange24h = priceChange24h
        _fiatBalanceProvider = TokenBalanceProviderTestsMock(balance: fiatBalance)
        _tokenItem = .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
        _id = WalletModelId(tokenItem: .blockchain(.init(.alephium(testnet: false), derivationPath: nil)))
        _isEmpty = false
        _fiatAvailableBalance = 0
        _account = nil
    }

    init(fiatBalanceProvider: TokenBalanceProvider, priceChange24h: Decimal?) {
        _fiatBalance = 0
        _priceChange24h = priceChange24h
        _fiatBalanceProvider = fiatBalanceProvider
        _tokenItem = .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
        _id = WalletModelId(tokenItem: .blockchain(.init(.alephium(testnet: false), derivationPath: nil)))
        _isEmpty = false
        _fiatAvailableBalance = 0
        _account = nil
    }

    init(
        tokenItem: TokenItem,
        isEmpty: Bool,
        fiatBalance: Decimal = 0,
        account: (any CryptoAccountModel)? = nil
    ) {
        _tokenItem = tokenItem
        _id = WalletModelId(tokenItem: tokenItem)
        _isEmpty = isEmpty
        _fiatBalance = fiatBalance
        _priceChange24h = nil
        _fiatBalanceProvider = TokenBalanceProviderTestsMock(balance: fiatBalance)
        _fiatAvailableBalance = fiatBalance
        _account = account
    }

    var quote: TokenQuote? {
        guard let priceChange24h = _priceChange24h else { return nil }
        return TokenQuote(
            currencyId: "mock",
            price: 1,
            priceUsd: nil,
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
    var statePublisher: AnyPublisher<WalletModelState, Never> { .just(output: state) }

    // MARK: - FiatTokenBalanceProviderInput

    var rate: WalletModelRate {
        if let quote = quote {
            return .loaded(quote: quote)
        } else {
            return .custom
        }
    }

    var ratePublisher: AnyPublisher<WalletModelRate, Never> { .just(output: rate) }

    // MARK: - StakingTokenBalanceProviderInput

    var stakingManagerState: StakingManagerState { .notEnabled }
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> { .just(output: stakingManagerState) }

    // MARK: - ReceiveAddressTypesProvider

    var receiveAddressTypes: [ReceiveAddressType] { [] }
    var receiveAddressTypesPublisher: AnyPublisher<[ReceiveAddressType], Never> { .just(output: []) }

    // MARK: - WalletModelResolvable

    func resolve<R>(using resolver: R) -> R.Result where R: WalletModelResolving {
        fatalError("resolve(using:) not implemented for MockWalletModel")
    }

    // MARK: - WalletModelUpdater

    func update(silent: Bool, features: [WalletModelUpdaterFeatureType]) async {}

    func updateTransactionsHistory() async {}

    func updateAfterSendingTransaction() {}

    // MARK: - WalletModelRentProvider

    func updateRentWarning() -> AnyPublisher<String?, Never> { .just(output: nil) }

    // MARK: - WalletModelFeesProvider

    var tokenFeeLoaderBuilder: TokenFeeLoaderBuilder { fatalError() }
    var customFeeProviderBuilder: CustomFeeProviderBuilder { fatalError() }

    // MARK: - TransactionHistoryFetcher

    var canFetchHistory: Bool { false }

    func clearHistory() {}

    // MARK: - WalletModel Protocol Stubs

    var id: WalletModelId { _id }

    var userWalletId: UserWalletId { UserWalletId(value: Data()) }
    var name: String { "Mock" }
    var addresses: [WalletAddress] {
        [WalletAddress(value: defaultAddressString, localizedName: "")]
    }

    var defaultAddressString: String { "mock" }

    var isMainToken: Bool { true }
    var tokenItem: TokenItem { _tokenItem }
    var feeTokenItem: TokenItem { tokenItem }
    var canUseQuotes: Bool { true }
    var isEmpty: Bool { _isEmpty }
    var publicKey: Wallet.PublicKey { Wallet.PublicKey(seedKey: Data(), derivationType: .none) }
    var isCustom: Bool { false }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var isAssetRequirementsTaskInProgressPublisher: AnyPublisher<Bool, Never> { .just(output: false) }
    var qrReceiveMessage: String { "" }
    var isDemo: Bool { false }
    var demoBalance: Decimal? { get { nil } set {} }
    var sendingRestrictions: SendingRestrictions? { nil }
    var features: [WalletModelFeature] { [] }
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> { Empty().eraseToAnyPublisher() }
    var stakingManager: StakingManager? { nil }
    var stakeKitTransactionSender: StakeKitTransactionSender? { nil }
    var p2pTransactionSender: (any P2PTransactionSender)? { nil }
    var account: (any CryptoAccountModel)? { _account }
    var yieldModuleManager: YieldModuleManager? { nil }
    var feeTokenItemBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var availableBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var stakingBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var totalTokenBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: _fiatAvailableBalance) }
    var fiatStakingBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }
    var blockchainDataProvider: BlockchainDataProvider { fatalError() }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { nil }
    var assetRequirementsManager: AssetRequirementsManager? { nil }
    var transactionFeeProvider: TransactionFeeProvider { fatalError() }
    var transactionCreator: TransactionCreator { fatalError() }
    var transactionValidator: TransactionValidator { fatalError() }
    var transactionSender: TransactionSender { fatalError() }
    var multipleTransactionsSender: MultipleTransactionsSender? { nil }
    var compiledTransactionFeeProvider: CompiledTransactionFeeProvider? { nil }
    var compiledTransactionSender: CompiledTransactionSender? { nil }
    var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder? { nil }
    var ethereumNetworkProvider: EthereumNetworkProvider? { nil }
    var ethereumTransactionSigner: EthereumTransactionSigner? { nil }
    var bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator? { nil }
    var accountInitializationService: BlockchainAccountInitializationService? { nil }
    var minimalBalanceProvider: MinimalBalanceProvider? { nil }
    var ethereumGaslessTransactionFeeProvider: (any GaslessTransactionFeeProvider)? { nil }
    var isSupportedTransactionHistory: Bool { false }
    var hasPendingTransactions: Bool { false }
    var hasAnyPendingTransactions: Bool { false }
    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> { Empty().eraseToAnyPublisher() }
    var pendingTransactionPublisher: AnyPublisher<[PendingTransactionRecord], Never> { Empty().eraseToAnyPublisher() }
    var isEmptyIncludingPendingIncomingTxs: Bool { false }
    var hasRent: Bool { false }
    var existentialDepositWarning: String? { nil }
    var ethereumGaslessDataProvider: (any EthereumGaslessDataProvider)? { nil }
    var pendingTransactionRecordAdder: (any PendingTransactionRecordAdding)? { nil }

    // MARK: - CustomStringConvertible

    var description: String { "WalletModelTestsMock" }

    func exploreURL(for address: WalletAddress, token: Token?) -> URL? { nil }
    func exploreTransactionURL(for hash: String) -> URL? { nil }
    func fulfillRequirements(signer: any TransactionSigner) -> AnyPublisher<Void, Error> { Empty().eraseToAnyPublisher() }
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> { Empty().eraseToAnyPublisher() }
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> { Empty().eraseToAnyPublisher() }
    func getFee(compiledTransaction data: Data) async throws -> [Fee] { [] }
    func hash(into hasher: inout Hasher) {}
    static func == (lhs: WalletModelTestsMock, rhs: WalletModelTestsMock) -> Bool { false }
}
