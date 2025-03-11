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

protocol WalletModel:
    AnyObject, Identifiable, Hashable, CustomStringConvertible,
    AvailableTokenBalanceProviderInput, WalletModelUpdater, WalletModelBalancesProvider,
    WalletModelHelpers, WalletModelFeeProvider, WalletModelDependenciesProvider,
    WalletModelTransactionHistoryProvider, WalletModelRentProvider, TransactionHistoryFetcher,
    ExpressWallet, StakingTokenBalanceProviderInput, FiatTokenBalanceProviderInput, ExistentialDepositInfoProvider {
    var id: WalletModelId { get }
    var name: String { get }
    var wallet: Wallet { get }
    var addresses: [String] { get }
    var addressNames: [String] { get }
    var isMainToken: Bool { get }
    var tokenItem: TokenItem { get }
    var feeTokenItem: TokenItem { get }
    var canUseQuotes: Bool { get }
    var quote: TokenQuote? { get }
    var shouldShowFeeSelector: Bool { get }
    var isCustom: Bool { get }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { get }
    var qrReceiveMessage: String { get }
    var balanceState: WalletModelBalanceState? { get }
    var isDemo: Bool { get }
    var demoBalance: Decimal? { get set }

    var sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions? { get }

    // Staking
    var stakingManager: StakingManager? { get }
    var stakeKitTransactionSender: StakeKitTransactionSender? { get }
    var accountInitializationStateProvider: StakingAccountInitializationStateProvider? { get }
}

extension WalletModel {
    func exploreURL(for index: Int) -> URL? {
        return exploreURL(for: index, token: nil)
    }
}

// MARK: - Update

protocol WalletModelUpdater {
    func generalUpdate(silent: Bool) -> AnyPublisher<Void, Never>
    /// Do not use with flatMap.
    @discardableResult
    func update(silent: Bool) -> AnyPublisher<WalletModelState, Never>

    func updateTransactionsHistory() -> AnyPublisher<Void, Never>
    func updateAfterSendingTransaction()
}

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

protocol WalletModelFeeProvider {
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error>
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error>
    func hasFeeCurrency(amountType: Amount.AmountType) -> Bool
}

// MARK: - Dependencies

protocol WalletModelDependenciesProvider {
    var blockchainDataProvider: BlockchainDataProvider { get }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { get }
    var assetRequirementsManager: AssetRequirementsManager? { get }
    var addressResolver: AddressResolver? { get }

    var transactionCreator: TransactionCreator { get }
    var transactionValidator: TransactionValidator { get }
    var transactionSender: TransactionSender { get }

    var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder? { get }
    var ethereumNetworkProvider: EthereumNetworkProvider? { get }
    var ethereumTransactionSigner: EthereumTransactionSigner? { get }

    var bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator? { get }
}

// MARK: - Tx history

protocol WalletModelTransactionHistoryProvider {
    var isSupportedTransactionHistory: Bool { get }
    var hasPendingTransactions: Bool { get }
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
    ///    var existentialDeposit: Amount? { get }
    var existentialDepositWarning: String? { get }
}
