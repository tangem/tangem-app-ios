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
        guard
            let rawTransactionType = item.tx.transactionType,
            let transactionType = SupportedTransactionType(rawValue: rawTransactionType)
        else {
            return nil
        }

        let isPayment = transactionType == .payment
        let transactionAmount: Decimal

        switch (amountType, transactionType) {
        case (.coin, .trustSet), (.reserve, .trustSet):
            return nil
        case (.coin, _), (.reserve, _):
            switch item.tx.amount {
            case .drops(let dropsAmountString):
                guard let amountInDrops = Decimal(stringValue: dropsAmountString) else {
                    return nil
                }

                transactionAmount = amountInDrops / blockchain.decimalValue
            case .issuedCurrency, nil:
                guard !isPayment else {
                    return nil
                }

                transactionAmount = 0
            }
        case (.token(let token), _):
            guard let tokenAmount = extractTokenAmount(
                from: item,
                token: token,
                transactionType: transactionType
            ) else {
                return nil
            }

            switch (transactionType, tokenAmount) {
            case (.trustSet, _):
                transactionAmount = 0
            case (_, 0):
                return nil
            default:
                transactionAmount = tokenAmount
            }
        case (.feeResource, _):
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
        let issuedAmount = item.tx.amount?.issuedCurrencyValue
        let isClawback = transactionType == .clawback
        let sourceAddress = isClawback ? issuedAmount?.issuer ?? item.tx.account : item.tx.account
        let isOutgoing = sourceAddress == walletAddress

        let destinationAddress: String = {
            if isClawback {
                return item.tx.account
            }

            if let destination = item.tx.destination {
                return destination
            }

            if transactionType == .trustSet, let trustlineIssuer = item.tx.limitAmount?.issuer {
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

        let recordType: TransactionRecord.TransactionType = if isPayment {
            .transfer
        } else {
            .contractMethodName(name: transactionType.rawValue)
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
            type: recordType,
            date: item.tx.date.map { Date(timeIntervalSince1970: TimeInterval($0 + Constants.xrplEpochOffset)) },
            tokenTransfers: [],
            nonce: nil
        )
    }

    func extractTokenAmount(
        from item: XRPTransactionInfo,
        token: Token,
        transactionType: SupportedTransactionType
    ) -> Decimal? {
        guard
            let issuedAmount = extractIssuedAmount(from: item, transactionType: transactionType),
            let tokenDetails = try? XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress)
        else {
            return nil
        }

        let hasMatchingCurrency = issuedAmount.currency == tokenDetails.currencyCode
        let hasMatchingIssuer = if transactionType == .clawback {
            item.tx.account == tokenDetails.issuer
        } else {
            issuedAmount.issuer == tokenDetails.issuer
        }

        guard hasMatchingCurrency, hasMatchingIssuer else {
            return nil
        }

        guard let tokenAmount = Decimal(stringValue: issuedAmount.value) else {
            return nil
        }

        return tokenAmount
    }

    func extractIssuedAmount(
        from item: XRPTransactionInfo,
        transactionType: SupportedTransactionType
    ) -> XRPIssuedCurrencyAmount? {
        // TrustSet operations store token data in `LimitAmount`.
        if transactionType == .trustSet {
            return item.tx.limitAmount
        }

        return item.tx.amount?.issuedCurrencyValue
    }
}

private extension XRPTransactionHistoryMapper {
    enum SupportedTransactionType: String {
        case payment = "Payment"
        case trustSet = "TrustSet"
        case offerCreate = "OfferCreate"
        case offerCancel = "OfferCancel"
        case accountDelete = "AccountDelete"
        case escrowCreate = "EscrowCreate"
        case escrowFinish = "EscrowFinish"
        case escrowCancel = "EscrowCancel"
        case clawback = "Clawback"
    }

    enum Constants {
        static let successResult = "tesSUCCESS"
        /// Offset between Ripple Epoch and Unix Epoch
        /// https://xrpl.org/docs/references/protocol/data-types/basic-data-types#specifying-time
        static let xrplEpochOffset = 946_684_800
    }
}
