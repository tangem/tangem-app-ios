//
//  NFTSendWalletModelProxy.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemNFT
import TangemStaking
import TangemFoundation

/// The send flow is heavily dependent on the `WalletModel`, so this proxy around the main token wallet model
/// (the main token for the NFT asset's chain) is used to fulfill those needs.
/// Most methods and properties here are just plain stubs though, since NFTs don't support certain features like
/// 'rent', 'staking' and so on.
final class NFTSendWalletModelProxy {
    let tokenItem: TokenItem

    private let asset: NFTAsset
    private let mainTokenWalletModel: any WalletModel
    private let tokenBalanceProvider: TokenBalanceProvider
    private let transactionSendAvailabilityProvider: TransactionSendAvailabilityProvider

    init(
        asset: NFTAsset,
        tokenItem: TokenItem,
        mainTokenWalletModel: any WalletModel,
        tokenBalanceProvider: TokenBalanceProvider,
        transactionSendAvailabilityProvider: TransactionSendAvailabilityProvider
    ) {
        assert(mainTokenWalletModel.isMainToken, "This proxy object is designed to work only with the main token wallet model")

        self.asset = asset
        self.tokenItem = tokenItem
        self.mainTokenWalletModel = mainTokenWalletModel
        self.tokenBalanceProvider = tokenBalanceProvider
        self.transactionSendAvailabilityProvider = transactionSendAvailabilityProvider
    }
}

// MARK: - WalletModel protocol conformance

extension NFTSendWalletModelProxy: WalletModel {
    var id: WalletModelId {
        WalletModelId(tokenItem: tokenItem)
    }

    var userWalletId: UserWalletId {
        mainTokenWalletModel.userWalletId
    }

    var name: String {
        asset.name
    }

    var addresses: [Address] {
        mainTokenWalletModel.addresses
    }

    var defaultAddress: Address {
        mainTokenWalletModel.defaultAddress
    }

    var addressNames: [String] {
        mainTokenWalletModel.addressNames
    }

    var isMainToken: Bool {
        false
    }

    var feeTokenItem: TokenItem {
        mainTokenWalletModel.feeTokenItem
    }

    var canUseQuotes: Bool {
        // No quotes for NFT in the Send flow
        false
    }

    var quote: TokenQuote? {
        // No quotes for NFT in the Send flow
        nil
    }

    var isEmpty: Bool {
        // The presence of an NFT asset implicitly means that we have a positive balance
        false
    }

    var publicKey: Wallet.PublicKey {
        mainTokenWalletModel.publicKey
    }

    var shouldShowFeeSelector: Bool {
        mainTokenWalletModel.shouldShowFeeSelector
    }

    var isCustom: Bool {
        // By definition, NFT assets can't be added by user
        false
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> {
        // No context actions for NFT
        .empty
    }

    var qrReceiveMessage: String {
        mainTokenWalletModel.qrReceiveMessage
    }

    var balanceState: WalletModelBalanceState? {
        // The presence of an NFT asset implicitly means that we have a positive balance
        .positive
    }

    var isDemo: Bool {
        // By definition, NFT assets can't be used in demo
        false
    }

    var demoBalance: Decimal? {
        // By definition, NFT assets can't be used in demo
        get { nil }
        set {}
    }

    var sendingRestrictions: SendingRestrictions? {
        transactionSendAvailabilityProvider.sendingRestrictions(walletModel: self)
    }

    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        // No additional features for NFT
        .just(output: [])
    }

    var stakingManager: StakingManager? {
        // No staking for NFT
        nil
    }

    var yieldModuleManager: YieldModuleManager? {
        mainTokenWalletModel.yieldModuleManager
    }

    var stakeKitTransactionSender: StakeKitTransactionSender? {
        // No staking for NFT
        nil
    }

    var p2pTransactionSender: P2PTransactionSender? {
        nil
    }

    var accountInitializationService: BlockchainAccountInitializationService? {
        // No staking for NFT
        nil
    }

    var minimalBalanceProvider: (any MinimalBalanceProvider)? {
        nil
    }

    var state: WalletModelState {
        tokenBalanceProvider.balanceType.value.map(WalletModelState.loaded) ?? .created
    }

    var statePublisher: AnyPublisher<WalletModelState, Never> {
        // The presence of an NFT asset implicitly means that all required data is already loaded
        .just(output: state)
    }

    func update(silent: Bool, features: [WalletModelUpdaterFeatureType]) async {
        await mainTokenWalletModel.update(silent: silent, features: features)
    }

    func updateTransactionsHistory() async {
        await mainTokenWalletModel.updateTransactionsHistory()
    }

    func updateAfterSendingTransaction() {
        mainTokenWalletModel.updateAfterSendingTransaction()
    }

    var availableBalanceProvider: TokenBalanceProvider {
        tokenBalanceProvider
    }

    var stakingBalanceProvider: TokenBalanceProvider {
        mainTokenWalletModel.stakingBalanceProvider
    }

    var totalTokenBalanceProvider: TokenBalanceProvider {
        tokenBalanceProvider
    }

    var fiatAvailableBalanceProvider: TokenBalanceProvider {
        mainTokenWalletModel.fiatAvailableBalanceProvider
    }

    var fiatStakingBalanceProvider: TokenBalanceProvider {
        mainTokenWalletModel.stakingBalanceProvider
    }

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider {
        mainTokenWalletModel.fiatTotalTokenBalanceProvider
    }

    func displayAddress(for index: Int) -> String {
        mainTokenWalletModel.displayAddress(for: index)
    }

    func shareAddressString(for index: Int) -> String {
        mainTokenWalletModel.shareAddressString(for: index)
    }

    func exploreURL(for index: Int, token: Token?) -> URL? {
        // NFTs have their own explorer URLs
        NFTExplorerLinkProvider().provide(for: asset.id)
    }

    func exploreTransactionURL(for hash: String) -> URL? {
        mainTokenWalletModel.exploreTransactionURL(for: hash)
    }

    func fulfillRequirements(signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        mainTokenWalletModel.fulfillRequirements(signer: signer)
    }

    var tokenFeeLoader: any TokenFeeLoader {
        mainTokenWalletModel.tokenFeeLoader
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        mainTokenWalletModel.customFeeProvider
    }

    func hasFeeCurrency() -> Bool {
        mainTokenWalletModel.hasFeeCurrency()
    }

    func getFeeCurrencyBalance() -> Decimal {
        mainTokenWalletModel.getFeeCurrencyBalance()
    }

    var blockchainDataProvider: BlockchainDataProvider {
        mainTokenWalletModel.blockchainDataProvider
    }

    var withdrawalNotificationProvider: WithdrawalNotificationProvider? {
        mainTokenWalletModel.withdrawalNotificationProvider
    }

    var assetRequirementsManager: AssetRequirementsManager? {
        mainTokenWalletModel.assetRequirementsManager
    }

    var transactionCreator: TransactionCreator {
        mainTokenWalletModel.transactionCreator
    }

    var transactionValidator: TransactionValidator {
        mainTokenWalletModel.transactionValidator
    }

    var transactionSender: TransactionSender {
        mainTokenWalletModel.transactionSender
    }

    var multipleTransactionsSender: (any MultipleTransactionsSender)? {
        mainTokenWalletModel.multipleTransactionsSender
    }

    var compiledTransactionSender: CompiledTransactionSender? {
        mainTokenWalletModel.compiledTransactionSender
    }

    var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder? {
        mainTokenWalletModel.ethereumTransactionDataBuilder
    }

    var ethereumNetworkProvider: EthereumNetworkProvider? {
        mainTokenWalletModel.ethereumNetworkProvider
    }

    var ethereumTransactionSigner: EthereumTransactionSigner? {
        mainTokenWalletModel.ethereumTransactionSigner
    }

    var bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator? {
        mainTokenWalletModel.bitcoinTransactionFeeCalculator
    }

    var isSupportedTransactionHistory: Bool {
        mainTokenWalletModel.isSupportedTransactionHistory
    }

    var hasPendingTransactions: Bool {
        mainTokenWalletModel.hasPendingTransactions
    }

    var hasAnyPendingTransactions: Bool {
        mainTokenWalletModel.hasAnyPendingTransactions
    }

    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> {
        mainTokenWalletModel.transactionHistoryPublisher
    }

    var pendingTransactionPublisher: AnyPublisher<[PendingTransactionRecord], Never> {
        mainTokenWalletModel.pendingTransactionPublisher
    }

    var isEmptyIncludingPendingIncomingTxs: Bool {
        // The presence of an NFT asset implicitly means that we have a positive balance
        false
    }

    var hasRent: Bool {
        // No rent for NFT
        false
    }

    func updateRentWarning() -> AnyPublisher<String?, Never> {
        // No rent for NFT
        .empty
    }

    var canFetchHistory: Bool {
        mainTokenWalletModel.canFetchHistory
    }

    func clearHistory() {
        mainTokenWalletModel.clearHistory()
    }

    var stakingManagerState: StakingManagerState {
        // No staking for NFT
        .notEnabled
    }

    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        // No staking for NFT
        .just(output: stakingManagerState)
    }

    var rate: WalletModelRate {
        // No rates for NFT
        .failure(cached: nil)
    }

    var ratePublisher: AnyPublisher<WalletModelRate, Never> {
        // No rates for NFT
        .just(output: rate)
    }

    var existentialDepositWarning: String? {
        // No existential deposit for NFT
        nil
    }

    var account: (any CryptoAccountModel)? {
        mainTokenWalletModel.account
    }

    static func == (lhs: NFTSendWalletModelProxy, rhs: NFTSendWalletModelProxy) -> Bool {
        lhs.id == rhs.id
    }

    var receiveAddressInfos: [ReceiveAddressInfo] {
        mainTokenWalletModel.receiveAddressInfos
    }

    var receiveAddressTypes: [ReceiveAddressType] {
        mainTokenWalletModel.receiveAddressTypes
    }

    func resolve<R>(using resolver: R) -> R.Result where R: WalletModelResolving {
        resolver.resolve(walletModel: self)
    }

    var ethereumGaslessTransactionFeeProvider: (any GaslessTransactionFeeProvider)? {
        mainTokenWalletModel.ethereumGaslessTransactionFeeProvider
    }

    var pendingTransactionRecordAdder: (any PendingTransactionRecordAdding)? {
        mainTokenWalletModel.pendingTransactionRecordAdder
    }

    var ethereumGaslessDataProvider: (any BlockchainSdk.EthereumGaslessDataProvider)? {
        mainTokenWalletModel.ethereumGaslessDataProvider
    }
}
