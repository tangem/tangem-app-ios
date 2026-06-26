//
//  TransactionDetailsMockData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation
import Combine
import BlockchainSdk
import TangemExpress

/// DEBUG-only fixtures: `TransactionRecord`s with populated Express `extraInfo`, so the swap / onramp
/// details sheet can be exercised end-to-end (leg/token resolution, provider, status, live header)
/// before the real enrichment pipeline is finished.
///
/// - Warning: Remove (or keep `isEnabled == false`) before opening a PR — it injects fake rows into
///   every token's history in DEBUG builds.
enum TransactionDetailsMockData {
    /// Master switch. Set to `true` to prepend mock swap/onramp rows to each token's history.
    static let isEnabled = true

    static let swapToFinishHash = "mock-swap-finish"
    static let swapToFailHash = "mock-swap-fail"
    static let onrampHash = "mock-onramp"

    static func injectingMocks(into records: [TransactionRecord], tokenItem: TokenItem) -> [TransactionRecord] {
        guard isEnabled else { return records }
        return [
            swapRecord(hash: swapToFinishHash, tokenItem: tokenItem, status: .created),
            swapRecord(hash: swapToFailHash, tokenItem: tokenItem, status: .created),
            onrampRecord(for: tokenItem),
        ] + records
    }

    /// For a mock swap row, a 5s-stepped publisher cycling the status sequence so the details sheet
    /// animates start → progress → finish (or → fail). `nil` for any non-mock row (real updates apply).
    static func liveUpdates(for transaction: TransactionViewModel, tokenItem: TokenItem) -> AnyPublisher<TransactionRecord, Never>? {
        guard isEnabled else { return nil }

        let statuses: [ExpressTransactionStatus]
        switch transaction.hash {
        case swapToFinishHash:
            statuses = [.created, .confirming, .exchanging, .finished]
        case swapToFailHash:
            statuses = [.created, .confirming, .exchanging, .failed]
        default:
            return nil
        }

        return Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .scan(0) { tick, _ in tick + 1 }
            .map { tick in
                swapRecord(hash: transaction.hash, tokenItem: tokenItem, status: statuses[tick % statuses.count])
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Swap (token → coin of the same network, both resolvable locally)

    private static func swapRecord(hash: String, tokenItem: TokenItem, status: ExpressTransactionStatus) -> TransactionRecord {
        let exchange = ExchangeTransaction(
            txId: hash,
            providerId: "changelly",
            status: status,
            rateType: .float,
            externalTx: ExternalTxInfo(id: "EXT-\(hash)", url: URL(string: "https://changelly.com")),
            fromAddress: "0xSender",
            payIn: PayInInfo(address: "0xPayIn", extraId: nil, hash: "0xPayInHash"),
            payOut: PayOutInfo(address: "0xPayOut", hash: nil),
            refund: nil,
            from: ExpressHistoryAsset(currency: tokenItem.expressCurrency.asCurrency, amount: 390, actualAmount: nil, decimals: tokenItem.decimalCount),
            to: ExpressHistoryAsset(currency: tokenItem.expressCoinCurrency.asCurrency, amount: 0.12, actualAmount: status == .finished ? 0.12 : nil, decimals: tokenItem.decimalCount),
            createdAt: Date(),
            updatedAt: Date(),
            payTill: nil,
            averageDuration: nil
        )

        return record(
            hash: hash,
            tokenItem: tokenItem,
            isOutgoing: true,
            status: recordStatus(for: status),
            type: .contractMethodName(name: "swap"),
            extraInfo: .exchange(.init(transaction: exchange, provider: provider(name: "Changelly", type: .cex)))
        )
    }

    private static func recordStatus(for status: ExpressTransactionStatus) -> TransactionRecord.TransactionStatus {
        switch status {
        case .finished: .confirmed
        case .failed, .txFailed, .refunded, .expired: .failed
        default: .unconfirmed
        }
    }

    // MARK: - Onramp (fiat → current token)

    private static func onrampRecord(for tokenItem: TokenItem) -> TransactionRecord {
        let onramp = OnrampTransaction(
            txId: "mock-onramp-tx",
            providerId: "mercuryo",
            status: .finished,
            failReason: nil,
            externalTx: ExternalTxInfo(id: "EXT-ONRAMP-456", url: URL(string: "https://mercuryo.io")),
            payOut: PayOutInfo(address: "0xPayOut", hash: nil),
            from: OnrampHistoryFiatAsset(currencyCode: "USD", amount: 391.12),
            to: OnrampHistoryCryptoAsset(currency: tokenItem.expressCurrency.asCurrency, amount: 0.0052, actualAmount: 0.0052, decimals: tokenItem.decimalCount),
            paymentMethod: "card",
            countryCode: "US",
            createdAt: Date(),
            updatedAt: Date()
        )

        let fiatCurrency = OnrampFiatCurrency(
            identity: OnrampIdentity(name: "US Dollar", code: "USD", image: nil),
            precision: 2
        )

        return record(
            hash: onrampHash,
            tokenItem: tokenItem,
            isOutgoing: false,
            status: .confirmed,
            type: .transfer,
            extraInfo: .onramp(.init(onrampTransaction: onramp, provider: provider(name: "Mercuryo", type: .onramp), fiatCurrency: fiatCurrency))
        )
    }

    // MARK: - Shared builders

    private static func record(
        hash: String,
        tokenItem: TokenItem,
        isOutgoing: Bool,
        status: TransactionRecord.TransactionStatus,
        type: TransactionRecord.TransactionType,
        extraInfo: TransactionRecord.TransactionRecordExtraInfo
    ) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: 0,
            source: .single(.init(address: "0xSender", amount: 390)),
            destination: .single(.init(address: .user("0xRecipient"), amount: 390)),
            fee: Fee(Amount(with: tokenItem.blockchain, value: 0.00056)),
            status: status,
            isOutgoing: isOutgoing,
            type: type,
            date: Date(),
            tokenTransfers: [],
            nonce: nil,
            extraInfo: extraInfo
        )
    }

    private static func provider(name: String, type: ExpressProviderType) -> ExpressProvider {
        ExpressProvider(
            id: name.lowercased(),
            name: name,
            type: type,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )
    }
}
#endif // DEBUG
