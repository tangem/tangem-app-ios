//
//  Wallet.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct Wallet {
    // MARK: - Properties

    public let blockchain: Blockchain
    public private(set) var walletAddresses: [AddressType: Address]

    public private(set) var amounts: [Amount.AmountType: Amount] = [:]
    public private(set) var pendingTransactions: [PendingTransactionRecord] = []

    // MARK: - Calculations

    public var addresses: [Address] { walletAddresses.map { $0.value }.sorted(by: { $0.type < $1.type }) }
    public var defaultAddress: Address { walletAddresses[.default]! }

    /// `publicKey` from default address
    public var publicKey: Wallet.PublicKey { defaultAddress.publicKey }

    /// Default address
    public var address: String { defaultAddress.value }

    public var isEmpty: Bool {
        return amounts.filter { $0.key != .reserve && !$0.value.isZero }.isEmpty
    }

    public var hasPendingTx: Bool {
        return !pendingTransactions.isEmpty
    }

    /// This variable is not meant to be read outside of the wallet and simply triggers
    /// willSet/didSet/CurrentValueSubject with the value of this `Wallet` to update.
    private var hasAssetRequirements: Bool = false

    public init(blockchain: Blockchain, addresses: [AddressType: Address]) {
        self.blockchain = blockchain
        walletAddresses = addresses
    }

    public func hasPendingTx(for amountType: Amount.AmountType) -> Bool {
        return pendingTransactions.contains { $0.amount.type == amountType }
    }

    /// Explore URL for a specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: URL
    public func getExploreURL(for address: String? = nil, token: Token? = nil) -> URL? {
        let address = address ?? self.address
        let provider = ExternalLinkProviderFactory().makeProvider(for: blockchain)
        return provider.url(address: address, contractAddress: token?.contractAddress)
    }

    /// Explore URL for a specific transaction by hash
    public func getExploreURL(for transaction: String) -> URL? {
        let provider = ExternalLinkProviderFactory().makeProvider(for: blockchain)
        return provider.url(transaction: transaction)
    }

    /// Will return faucet URL for only testnet blockchain. Should use for top-up wallet
    public func getTestnetFaucetURL() -> URL? {
        let provider = ExternalLinkProviderFactory().makeProvider(for: blockchain)
        return provider.testnetFaucetURL
    }

    /// Share string for specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: String to share
    public func getShareString(for address: String? = nil) -> String {
        let address = address ?? self.address
        return blockchain.getShareString(from: address)
    }

    public mutating func add(coinValue: Decimal) {
        let coinAmount = Amount(with: blockchain, type: .coin, value: coinValue)
        add(amount: coinAmount)
    }

    public mutating func add(reserveValue: Decimal) {
        let reserveAmount = Amount(with: blockchain, type: .reserve, value: reserveValue)
        add(amount: reserveAmount)
    }

    @discardableResult
    public mutating func add(tokenValue: Decimal, for token: Token) -> Amount {
        let tokenAmount = Amount(with: token, value: tokenValue)
        add(amount: tokenAmount)
        return tokenAmount
    }

    public mutating func add(amount: Amount) {
        amounts[amount.type] = amount
    }

    // MARK: - Fees

    public func feeCurrencyBalance(amountType: Amount.AmountType) -> Decimal {
        let feeAmountType = feeAmountType(transactionAmountType: amountType)
        let feeAmount = amounts[feeAmountType]?.value ?? 0

        return feeAmount
    }

    public func hasFeeCurrency(amountType: Amount.AmountType) -> Bool {
        let feeValue = feeCurrencyBalance(amountType: amountType)

        if blockchain.allowsZeroFeePaid {
            return feeValue >= 0
        }

        return feeValue > 0
    }

    // MARK: - Internal

    mutating func clearAmounts() {
        amounts = [:]
    }

    mutating func clearAmount(for token: Token) {
        amounts[.token(value: token)] = nil
    }

    mutating func set(address: Address) {
        walletAddresses[address.type] = address
    }

    private func feeAmountType(transactionAmountType: Amount.AmountType) -> Amount.AmountType {
        switch blockchain.feePaidCurrency {
        case .coin:
            return .coin
        case .token(let value):
            return .token(value: value)
        case .sameCurrency:
            return transactionAmountType
        // Currently, we use this only for Koinos.
        // The MANA (fee resource) amount can only be zero if the KOIN (coin) amount is zero.
        // There is a network restriction that prohibits sending the maximum amount of KOIN,
        // which explicitly means there will always be some KOIN.
        // This also implicitly means there will always be some amount of MANA,
        // because 1 KOIN is able to recharge at a rate of 0.00000231 Mana per second,
        // and this recharge rate scales correspondingly to the amount of KOIN in the balance.
        case .feeResource(let type):
            return .feeResource(type)
        }
    }
}

// MARK: - Pending Transaction

extension Wallet {
    mutating func updatePendingTransaction(_ transactions: [PendingTransactionRecord]) {
        pendingTransactions = transactions
    }

    mutating func addPendingTransaction(_ transaction: PendingTransactionRecord) {
        if pendingTransactions.contains(where: { $0.hash == transaction.hash }) {
            return
        }

        pendingTransactions.append(transaction)
    }

    mutating func addDummyPendingTransaction() {
        let mapper = PendingTransactionRecordMapper()
        let record = mapper.makeDummy(blockchain: blockchain)

        addPendingTransaction(record)
    }

    mutating func removePendingTransaction(where compare: (String) -> Bool) {
        pendingTransactions.removeAll { transaction in
            compare(transaction.hash)
        }
    }

    mutating func removePendingTransaction(older date: Date) {
        pendingTransactions.removeAll { transaction in
            transaction.date < date
        }
    }

    mutating func clearPendingTransaction() {
        pendingTransactions.removeAll()
    }

    mutating func setAssetRequirements() {
        hasAssetRequirements = true
    }

    mutating func clearAssetRequirements() {
        hasAssetRequirements = false
    }
}
