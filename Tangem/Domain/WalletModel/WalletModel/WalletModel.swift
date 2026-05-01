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
    WalletModelHelpers, WalletModelFeesProvider, WalletModelDependenciesProvider,
    WalletModelRentProvider, WalletModelHistoryUpdater, TransactionHistoryFetcher,
    StakingTokenBalanceProviderInput, FiatTokenBalanceProviderInput, ExistentialDepositInfoProvider,
    ReceiveAddressTypesProvider, WalletModelResolvable {
    var id: WalletModelId { get }
    var userWalletId: UserWalletId { get }
    var name: String { get }
    var addresses: [Address] { get }
    var defaultAddress: Address { get }
    var isMainToken: Bool { get }
    var tokenItem: TokenItem { get }
    var feeTokenItem: TokenItem { get }
    var canUseQuotes: Bool { get }
    var quote: TokenQuote? { get }

    var isEmpty: Bool { get }
    var publicKey: Wallet.PublicKey { get }
    var isCustom: Bool { get }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { get }
    var isAssetRequirementsTaskInProgressPublisher: AnyPublisher<Bool, Never> { get }
    var qrReceiveMessage: String { get }
    var isDemo: Bool { get }
    var demoBalance: Decimal? { get set }

    var sendingRestrictions: SendingRestrictions? { get }

    var features: [WalletModelFeature] { get }
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

    var addressesString: [String] { addresses.map(\.value) }

    var defaultAddressString: String { defaultAddress.value }

    func exploreURL(for address: String) -> URL? {
        return exploreURL(for: address, token: nil)
    }

    var walletConnectAddress: String {
        let factory = EthereumAddressConverterFactory()
        let converter = factory.makeConverter(for: tokenItem.blockchain)
        let convertedAddress = try? converter.convertToETHAddress(defaultAddressString)
        return convertedAddress ?? defaultAddressString
    }
}

extension WalletModel {
    func getFeeCurrencyBalance() -> Decimal {
        feeTokenItemBalanceProvider.balanceType.loaded ?? 0
    }

    func hasFeeCurrency() -> Bool {
        if tokenItem.blockchain.allowsZeroFeePaid {
            return getFeeCurrencyBalance() >= 0
        }

        return getFeeCurrencyBalance() > 0
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
    var feeTokenItemBalanceProvider: TokenBalanceProvider { get }
    var availableBalanceProvider: TokenBalanceProvider { get }
    var stakingBalanceProvider: TokenBalanceProvider { get }
    var totalTokenBalanceProvider: TokenBalanceProvider { get }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }
    var fiatStakingBalanceProvider: TokenBalanceProvider { get }
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
}

// MARK: - Dependencies

protocol WalletModelDynamicAddressesProvider {
    var dynamicAddressesEnablingRequirements: DynamicAddressesEnablingRequirements? { get }
    var dynamicAddressesDisablingRequirements: DynamicAddressesDisablingRequirements? { get }

    @MainActor
    func hasDynamicAddressesBalancesFlag() async -> Bool

    @MainActor
    func enableDynamicAddresses() async throws

    @MainActor
    func disableDynamicAddresses() async throws
}

// MARK: - Helpers

protocol WalletModelHelpers {
    func exploreURL(for address: String, token: Token?) -> URL?
    func exploreTransactionURL(for hash: String) -> URL?
    func fulfillRequirements(signer: any TransactionSigner) -> AnyPublisher<Void, Error>
}

// MARK: - Fee

protocol WalletModelFeesProvider {
    var tokenFeeLoaderBuilder: TokenFeeLoaderBuilder { get }
    var customFeeProviderBuilder: CustomFeeProviderBuilder { get }
}

// MARK: - Dependencies

protocol WalletModelDependenciesProvider {
    var blockchainDataProvider: BlockchainDataProvider { get }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { get }
    var assetRequirementsManager: AssetRequirementsManager? { get }

    var transactionFeeProvider: TransactionFeeProvider { get }
    var transactionCreator: TransactionCreator { get }
    var transactionValidator: TransactionValidator { get }
    var transactionSender: TransactionSender { get }

    var multipleTransactionsSender: MultipleTransactionsSender? { get }

    var compiledTransactionFeeProvider: CompiledTransactionFeeProvider? { get }
    var compiledTransactionSender: CompiledTransactionSender? { get }

    var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder? { get }
    var ethereumNetworkProvider: EthereumNetworkProvider? { get }
    var ethereumTransactionSigner: EthereumTransactionSigner? { get }

    var bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator? { get }

    var accountInitializationService: BlockchainAccountInitializationService? { get }
    var minimalBalanceProvider: MinimalBalanceProvider? { get }

    // MARK: - Gasless Transactions

    var ethereumGaslessTransactionFeeProvider: (any GaslessTransactionFeeProvider)? { get }
    var ethereumGaslessDataProvider: (any EthereumGaslessDataProvider)? { get }
    var pendingTransactionRecordAdder: (any PendingTransactionRecordAdding)? { get }
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
