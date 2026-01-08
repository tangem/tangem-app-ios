//
//  WalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemStaking
import TangemFoundation

protocol WalletModel:
    AnyObject, Identifiable, Hashable, CustomStringConvertible,
    AvailableTokenBalanceProviderInput, WalletModelBalancesProvider,
    WalletModelHelpers, WalletModelFeesProvider, WalletModelFeeProvider, WalletModelDependenciesProvider,
    WalletModelRentProvider, WalletModelHistoryUpdater, TransactionHistoryFetcher,
    StakingTokenBalanceProviderInput, FiatTokenBalanceProviderInput, ExistentialDepositInfoProvider,
    ReceiveAddressTypesProvider, WalletModelResolvable {
    var id: WalletModelId { get }
    var userWalletId: UserWalletId { get }
    var name: String { get }
    var addresses: [Address] { get }
    var defaultAddress: Address { get }
    var defaultAddressString: String { get }
    var addressNames: [String] { get }
    var isMainToken: Bool { get }
    var tokenItem: TokenItem { get }
    var feeTokenItem: TokenItem { get }
    var canUseQuotes: Bool { get }
    var quote: TokenQuote? { get }

    var isEmpty: Bool { get }
    var publicKey: Wallet.PublicKey { get }
    var shouldShowFeeSelector: Bool { get }
    var isCustom: Bool { get }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { get }
    var isAssetRequirementsTaskInProgressPublisher: AnyPublisher<Bool, Never> { get }
    var qrReceiveMessage: String { get }
    var balanceState: WalletModelBalanceState? { get }
    var isDemo: Bool { get }
    var demoBalance: Decimal? { get set }

    var sendingRestrictions: SendingRestrictions? { get }

    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> { get }

    // MARK: - Staking

    var stakingManager: StakingManager? { get }
    var stakeKitTransactionSender: StakeKitTransactionSender? { get }
    var p2pTransactionSender: P2PTransactionSender? { get }

    // MARK: - Accounts

    /// - Warning: Weak property, has the meaningful value only when accounts feature toggle is enabled.
    var account: (any CryptoAccountModel)? { get }

    // MARK: - Yield

    // [REDACTED_TODO_COMMENT]
    var yieldModuleManager: YieldModuleManager? { get }
}

extension WalletModel {
    /// Default implementation provided because not all wallet models support fulfilling asset requirements
    var isAssetRequirementsTaskInProgressPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }

    func exploreURL(for index: Int) -> URL? {
        return exploreURL(for: index, token: nil)
    }

    var defaultAddressString: String {
        defaultAddress.value
    }

    var walletConnectAddress: String {
        let factory = EthereumAddressConverterFactory()
        let converter = factory.makeConverter(for: tokenItem.blockchain)
        let convertedAddress = try? converter.convertToETHAddress(defaultAddress.value)
        return convertedAddress ?? defaultAddressString
    }
}

// MARK: - WalletModelUpdater

protocol WalletModelUpdater {
    func update(silent: Bool, features: [WalletModelUpdaterFeatureType]) async

    func updateTransactionsHistory() async
    func updateAfterSendingTransaction()
}

extension WalletModelUpdater {
    /// It can be call as `Fire-and-forget` update
    @discardableResult
    func startUpdateTask(silent: Bool = false, features: [WalletModelUpdaterFeatureType] = .full) -> Task<Void, Never> {
        Task { await update(silent: silent, features: features) }
    }
}

enum WalletModelUpdaterFeatureType {
    case balances
    case transactionHistory
}

extension [WalletModelUpdaterFeatureType] {
    static let balances: [WalletModelUpdaterFeatureType] = [.balances]
    static let full: [WalletModelUpdaterFeatureType] = [.balances, .transactionHistory]
}

// MARK: - WalletModelBalancesProvider

protocol WalletModelBalancesProvider {
    var availableBalanceProvider: TokenBalanceProvider { get }
    var stakingBalanceProvider: TokenBalanceProvider { get }
    var totalTokenBalanceProvider: TokenBalanceProvider { get }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }
    var fiatStakingBalanceProvider: TokenBalanceProvider { get }
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
}

// MARK: - Helpers

protocol WalletModelHelpers {
    func displayAddress(for index: Int) -> String
    func shareAddressString(for index: Int) -> String
    func exploreURL(for index: Int, token: Token?) -> URL?
    func exploreTransactionURL(for hash: String) -> URL?
    func fulfillRequirements(signer: any TransactionSigner) -> AnyPublisher<Void, Error>
}

// MARK: - Fee

protocol WalletModelFeesProvider {
    var tokenFeeProviders: [any TokenFeeProvider] { get }
    var tokenFeeLoader: any TokenFeeLoader { get }
    var customFeeProvider: (any CustomFeeProvider)? { get }
}

extension WalletModelFeesProvider {
    var tokenFeeProviders: [any TokenFeeProvider] { [] }
}

protocol WalletModelFeeProvider {
    func getFeeCurrencyBalance() -> Decimal
    func hasFeeCurrency() -> Bool
}

// MARK: - Dependencies

protocol WalletModelDependenciesProvider {
    var blockchainDataProvider: BlockchainDataProvider { get }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { get }
    var assetRequirementsManager: AssetRequirementsManager? { get }

    var transactionCreator: TransactionCreator { get }
    var transactionValidator: TransactionValidator { get }
    var transactionSender: TransactionSender { get }

    var multipleTransactionsSender: MultipleTransactionsSender? { get }

    var compiledTransactionSender: CompiledTransactionSender? { get }

    var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder? { get }
    var ethereumNetworkProvider: EthereumNetworkProvider? { get }
    var ethereumTransactionSigner: EthereumTransactionSigner? { get }

    var bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator? { get }

    var accountInitializationService: BlockchainAccountInitializationService? { get }
    var minimalBalanceProvider: MinimalBalanceProvider? { get }
}

// MARK: - Tx history

protocol WalletModelHistoryUpdater: WalletModelTransactionHistoryProvider & WalletModelUpdater {}

protocol WalletModelTransactionHistoryProvider {
    var isSupportedTransactionHistory: Bool { get }
    var hasPendingTransactions: Bool { get }
    /// Any pending transactions for the whole network. Coin, token, etc.
    var hasAnyPendingTransactions: Bool { get }
    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> { get }
    var pendingTransactionPublisher: AnyPublisher<[PendingTransactionRecord], Never> { get }
    var isEmptyIncludingPendingIncomingTxs: Bool { get }
}

// MARK: - Rent

protocol WalletModelRentProvider {
    var hasRent: Bool { get }
    func updateRentWarning() -> AnyPublisher<String?, Never>
}

// MARK: - Existential deposit

protocol ExistentialDepositInfoProvider {
    var existentialDepositWarning: String? { get }
}

protocol FeeResourceInfoProvider {
    var feeResourceBalance: Decimal? { get }
    var maxResourceBalance: Decimal? { get }
}
