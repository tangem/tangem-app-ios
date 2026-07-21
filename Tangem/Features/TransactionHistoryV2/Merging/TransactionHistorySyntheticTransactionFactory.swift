//
//  TransactionHistorySyntheticTransactionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

/// Builds synthetic `TransactionRecord` placeholders for Express (swap) and onramp transactions that have no
/// matching on-chain transaction (e.g. a still in-flight deal), so they're still surfaced in the history.
struct TransactionHistorySyntheticTransactionFactory {
    @Injected(\.transactionHistoryAuxDataRepository) private var auxDataRepository: TransactionHistoryAuxDataRepository

    private let ownerAddress: String
    private let currentToken: TokenItem
    private let feeTokenItem: TokenItem

    init(
        ownerAddress: String,
        currentToken: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.ownerAddress = ownerAddress
        self.currentToken = currentToken
        self.feeTokenItem = feeTokenItem
    }

    func makeSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> TransactionRecord {
        let provider = auxDataRepository.provider(id: exchangeTransaction.providerId, branch: .swap)
        let cryptoCurrencies = auxDataRepository.cryptoCurrencies(for: exchangeTransaction.expressCurrencies)
        let info = ExchangeTransactionInfo(
            transaction: exchangeTransaction,
            provider: provider,
            cryptoCurrencies: cryptoCurrencies
        )
        let outgoing = isOutgoing(exchangeTransaction)
        let source: TransactionRecord.SourceType
        let destination: TransactionRecord.DestinationType
        let hash: String

        if outgoing {
            // Pay-in leg: the wallet sends the `from` asset to the provider deposit address.
            let amount = exchangeTransaction.from.actualAmount ?? exchangeTransaction.from.amount
            source = .single(.init(address: exchangeTransaction.fromAddress ?? ownerAddress, amount: amount))
            destination = .single(.init(address: .user(exchangeTransaction.payIn.address), amount: amount))
            hash = exchangeTransaction.payIn.hash ?? exchangeTransaction.txId
        } else {
            // Pay-out leg: the wallet receives the `to` asset at its payout address.
            let amount = exchangeTransaction.to.actualAmount ?? exchangeTransaction.to.amount
            // The source address of the pay-out leg is unknown at this point because there is no blockchain transaction yet
            source = .single(.init(address: .unknown, amount: amount))
            destination = .single(.init(address: .user(exchangeTransaction.payOut.address), amount: amount))
            hash = exchangeTransaction.payOut.hash ?? exchangeTransaction.txId
        }

        return TransactionRecord(
            hash: hash,
            index: 0, // A single transaction record, therefore index is always 0
            source: source,
            destination: destination,
            fee: feeTokenItem.zeroFee, // Unknown at this point because there is no blockchain transaction yet
            status: syntheticTransactionStatus(from: exchangeTransaction.status),
            isOutgoing: outgoing,
            type: .contractMethodName(name: Constants.swapMethodName),
            date: exchangeTransaction.createdAt,
            tokenTransfers: [], // No inner token transfers for exchange transactions because no such information is provided by the API
            nonce: nil, // No on-chain nonce for a synthetic record
            extraInfo: TransactionHistoryExpressExtraInfo.exchange(info)
        )
    }

    func makeSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> TransactionRecord {
        // Onramp only has a pay-out leg (fiat -> crypto), so the synthetic transactions for Onramp are always incoming
        let amount = onrampTransaction.to.actualAmount ?? onrampTransaction.to.amount ?? 0
        let provider = auxDataRepository.provider(id: onrampTransaction.providerId, branch: .onramp)
        let fiatCurrency = auxDataRepository.fiatCurrency(for: onrampTransaction.from)
        let cryptoCurrencies = auxDataRepository.cryptoCurrencies(for: onrampTransaction.expressCurrencies)
        let info = OnrampTransactionInfo(
            onrampTransaction: onrampTransaction,
            provider: provider,
            fiatCurrency: fiatCurrency,
            cryptoCurrencies: cryptoCurrencies
        )

        return TransactionRecord(
            hash: onrampTransaction.payOut.hash ?? onrampTransaction.txId,
            index: 0, // A single transaction record, therefore index is always 0
            // The source address of the pay-out leg is unknown at this point because there is no blockchain transaction yet
            source: .single(.init(address: .unknown, amount: amount)),
            destination: .single(.init(address: .user(onrampTransaction.payOut.address), amount: amount)),
            fee: feeTokenItem.zeroFee, // Unknown at this point because there is no blockchain transaction yet
            status: syntheticTransactionStatus(from: onrampTransaction.status),
            isOutgoing: false, // Onramp transactions are always incoming by definition (fiat -> crypto)
            type: .contractMethodName(name: Constants.onrampMethodName),
            date: onrampTransaction.createdAt,
            tokenTransfers: [], // No inner token transfers for onramp transactions by definition
            nonce: nil, // No on-chain nonce for a synthetic record
            extraInfo: TransactionHistoryExpressExtraInfo.onramp(info)
        )
    }

    private func isOutgoing(_ exchangeTransaction: ExchangeTransaction) -> Bool {
        // Fast path: using the owner address to determine the direction
        let isOnSendLeg = exchangeTransaction.fromAddress.map { ownerAddress.caseInsensitiveEquals(to: $0) } ?? false
        let isOnReceiveLeg = ownerAddress.caseInsensitiveEquals(to: exchangeTransaction.payOut.address)

        if isOnSendLeg != isOnReceiveLeg {
            return isOnSendLeg
        }

        // Slow path: the address is ambiguous (owner on both or neither leg, e.g. a swap sent to self),
        // using current token to determine the direction
        return currentToken.expressCurrency.asCurrency == exchangeTransaction.from.currency
    }

    private func syntheticTransactionStatus(from status: ExpressTransactionStatus) -> TransactionRecord.TransactionStatus {
        switch status {
        case .finished,
             .refunded:
            return .confirmed
        case .failed,
             .txFailed:
            return .failed
        case .unknown,
             .preview,
             .created,
             .exchangeTxSent,
             .waiting,
             .waitingTxHash,
             .expired,
             .confirming,
             .exchanging,
             .sending,
             .verifying,
             .paused:
            return .unconfirmed
        }
    }

    private func syntheticTransactionStatus(from status: OnrampTransactionStatus) -> TransactionRecord.TransactionStatus {
        switch status {
        case .finished,
             .refunded:
            return .confirmed
        case .failed:
            return .failed
        case .unknown,
             .created,
             .expired,
             .waitingForPayment,
             .paymentProcessing,
             .verifying,
             .paid,
             .sending,
             .refunding,
             .paused:
            return .unconfirmed
        }
    }
}

// MARK: - Constants

private extension TransactionHistorySyntheticTransactionFactory {
    enum Constants {
        static let swapMethodName = "swap"
        static let onrampMethodName = "onramp"
    }
}
