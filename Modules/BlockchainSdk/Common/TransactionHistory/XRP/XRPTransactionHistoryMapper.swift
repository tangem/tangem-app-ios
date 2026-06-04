//
//  XRPTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils

final class XRPTransactionHistoryMapper {
    private let blockchain: Blockchain
    private var transactionIndicesCounter: [String: Int] = [:]

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

extension XRPTransactionHistoryMapper: TransactionHistoryMapper {
    func reset() {
        transactionIndicesCounter.removeAll()
    }

    func mapToTransactionRecords(
        _ response: [XRPTransactionInfo],
        walletAddress: String,
        amountType: Amount.AmountType
    ) throws -> [TransactionRecord] {
        return response.compactMap { item in
            mapToTransactionRecord(item: item, walletAddress: walletAddress, amountType: amountType)
        }
    }
}

private extension XRPTransactionHistoryMapper {
    func mapToTransactionRecord(
        item: XRPTransactionInfo,
        walletAddress: String,
        amountType: Amount.AmountType
    ) -> TransactionRecord? {
        let transactionAmount: Decimal

        switch amountType {
        case .coin, .reserve:
            guard
                let dropsAmountString = item.tx.amount?.dropsValue,
                let amountInDrops = Decimal(stringValue: dropsAmountString)
            else {
                return nil
            }

            transactionAmount = amountInDrops / blockchain.decimalValue
        case .token(let token):
            guard
                let tokenAmount = extractTokenAmount(from: item, token: token),
                tokenAmount != 0
            else {
                return nil
            }

            transactionAmount = tokenAmount
        case .feeResource:
            return nil
        }

        guard
            let hash = item.tx.hash,
            let feeString = item.tx.fee,
            let feeInDrops = Decimal(stringValue: feeString)
        else {
            return nil
        }

        let feeAmount = feeInDrops / blockchain.decimalValue
        let sourceAddress = item.tx.account
        let isOutgoing = sourceAddress == walletAddress

        let destinationAddress: String = {
            if let destination = item.tx.destination {
                return destination
            }

            if item.tx.transactionType == Constants.trustSetTransactionType,
               let trustlineIssuer = item.tx.limitAmount?.issuer {
                return trustlineIssuer
            }

            return walletAddress
        }()

        let status: TransactionRecord.TransactionStatus = {
            if let transactionResult = item.meta?.transactionResult, transactionResult != Constants.successResult {
                return .failed
            }

            if item.validated == true {
                return .confirmed
            }

            return .unconfirmed
        }()

        let transactionType: TransactionRecord.TransactionType = if item.tx.transactionType == Constants.paymentTransactionType {
            .transfer
        } else {
            .contractMethodName(name: item.tx.transactionType)
        }

        let index = transactionIndicesCounter[hash, default: 0]
        transactionIndicesCounter[hash] = index + 1

        return TransactionRecord(
            hash: hash,
            index: index,
            source: .single(.init(address: sourceAddress, amount: transactionAmount)),
            destination: .single(.init(address: .user(destinationAddress), amount: transactionAmount)),
            fee: Fee(Amount(with: blockchain, value: feeAmount)),
            status: status,
            isOutgoing: isOutgoing,
            type: transactionType,
            date: item.tx.date.map { Date(timeIntervalSince1970: TimeInterval($0 + Constants.xrplEpochOffset)) }
        )
    }

    func extractTokenAmount(from item: XRPTransactionInfo, token: Token) -> Decimal? {
        guard
            let issuedAmount = extractIssuedAmount(from: item),
            let tokenDetails = try? XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress)
        else {
            return nil
        }

        let hasMatchingCurrency = issuedAmount.currency == tokenDetails.currencyCode
        let hasMatchingIssuer = issuedAmount.issuer == tokenDetails.issuer

        guard hasMatchingCurrency, hasMatchingIssuer else {
            return nil
        }

        guard let tokenAmount = Decimal(stringValue: issuedAmount.value) else {
            return nil
        }

        return tokenAmount
    }

    func extractIssuedAmount(from item: XRPTransactionInfo) -> XRPIssuedCurrencyAmount? {
        // TrustSet operations store token data in `LimitAmount`.
        if item.tx.transactionType == Constants.trustSetTransactionType {
            return item.tx.limitAmount
        }

        return item.tx.amount?.issuedCurrencyValue
    }
}

private extension XRPTransactionHistoryMapper {
    enum Constants {
        static let paymentTransactionType = "Payment"
        static let trustSetTransactionType = "TrustSet"
        static let successResult = "tesSUCCESS"
        /// Offset between Ripple Epoch and Unix Epoch
        /// https://xrpl.org/docs/references/protocol/data-types/basic-data-types#specifying-time
        static let xrplEpochOffset = 946_684_800
    }
}
