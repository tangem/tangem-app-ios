//
//  KaspaTransactionHistoryMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class KaspaTransactionHistoryMapper {
    typealias Input = KaspaTransactionHistoryResponse.Transaction.Input
    typealias Output = KaspaTransactionHistoryResponse.Transaction.Output

    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        guard case .kaspa = blockchain else {
            fatalError("Invalid mapper for blockchain: \(blockchain)")
        }
        self.blockchain = blockchain
    }

    private func extractTransactionAmount(
        transaction: KaspaTransactionHistoryResponse.Transaction,
        isOutgoing: Bool,
        fee: Int,
        walletAddress: String
    ) -> Decimal? {
        let amount = transaction.outputs
            .filter {
                isOutgoing ? $0.scriptPublicKeyAddress != walletAddress : $0.scriptPublicKeyAddress == walletAddress
            }
            .reduce(0) { $0 + ($1.amount ?? 0) }

        let amountWithFee = if isOutgoing {
            amount + fee
        } else {
            amount
        }

        return Decimal(amountWithFee) / blockchain.decimalValue
    }

    private func extractDestination(
        transaction: KaspaTransactionHistoryResponse.Transaction,
        isOutgoing: Bool,
        amount: Decimal,
        walletAddress: String
    ) -> TransactionRecord.DestinationType? {
        if isOutgoing {
            let outputAddresses = transaction.outputs.compactMap { output -> TransactionRecord.Destination? in
                guard let address = output.scriptPublicKeyAddress, address != walletAddress else {
                    return nil
                }

                return TransactionRecord.Destination(address: .user(address), amount: amount)
            }

            switch outputAddresses.count {
            case 0: return nil
            case 1:
                guard let firstAddress = outputAddresses.first else { return nil }
                return .single(firstAddress)
            default:
                return .multiple(outputAddresses)
            }
        } else {
            return TransactionRecord.DestinationType.single(.init(address: .user(walletAddress), amount: amount))
        }
    }

    private func extractSource(
        transaction: KaspaTransactionHistoryResponse.Transaction,
        amount: Decimal,
        isOutgoing: Bool,
        walletAddress: String
    ) -> TransactionRecord.SourceType? {
        if isOutgoing {
            return .single(.init(address: walletAddress, amount: amount))
        } else if transaction.inputs.isNotEmpty {
            return transaction.inputs
                .first { $0.previousOutpointAddress != nil && $0.previousOutpointAddress != walletAddress }
                .flatMap { $0.previousOutpointAddress.map { .single(.init(address: $0, amount: amount)) } }
        } else {
            return .single(.init(address: "", amount: amount))
        }
    }

    private func calculateFee(inputs: [Input], outputs: [Output]) -> Int {
        let inputSum = inputs.compactMap { $0.previousOutpointAmount }.reduce(0, +)
        let outputSum = outputs.compactMap { $0.amount }.reduce(0, +)
        return max(0, inputSum - outputSum)
    }
}

// MARK: - TransactionHistoryMapper protocol conformance

extension KaspaTransactionHistoryMapper: TransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: [KaspaTransactionHistoryResponse.Transaction],
        walletAddress: String,
        amountType: Amount.AmountType
    ) throws -> [TransactionRecord] {
        return response.compactMap { transaction -> TransactionRecord? in
            let isOutgoing = transaction.inputs.contains(where: { $0.previousOutpointAddress == walletAddress })
            let fee = calculateFee(inputs: transaction.inputs, outputs: transaction.outputs)
            var transactionStatus: TransactionRecord.TransactionStatus {
                guard let status = transaction.isAccepted else {
                    return .undefined
                }

                return status ? .confirmed : .unconfirmed
            }

            guard let transactonId = transaction.transactionId?.nilIfEmpty else {
                return nil
            }

            guard let amount = extractTransactionAmount(
                transaction: transaction,
                isOutgoing: isOutgoing,
                fee: fee,
                walletAddress: walletAddress
            ) else {
                return nil
            }

            guard let destination = extractDestination(
                transaction: transaction,
                isOutgoing: isOutgoing,
                amount: amount,
                walletAddress: walletAddress
            ) else {
                return nil
            }

            guard let source = extractSource(
                transaction: transaction,
                amount: amount,
                isOutgoing: isOutgoing,
                walletAddress: walletAddress
            ) else {
                return nil
            }

            return TransactionRecord(
                hash: transactonId,
                index: 0,
                source: source,
                destination: destination,
                fee: Fee(Amount(with: blockchain, value: Decimal(fee))),
                status: transactionStatus,
                isOutgoing: isOutgoing,
                type: .transfer,
                date: transaction.blockTime
            )
        }
    }
}
