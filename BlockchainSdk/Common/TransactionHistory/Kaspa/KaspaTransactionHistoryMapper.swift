//
//  KaspaTransactionHistoryMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class KaspaTransactionHistoryMapper {
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
            .reduce(0) { $0 + $1.amount }

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
            let outputAddresses = transaction.outputs
                .filter { $0.scriptPublicKeyAddress != walletAddress }
                .map { TransactionRecord.Destination(address: .user($0.scriptPublicKeyAddress), amount: amount) }

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
            .single(.init(address: walletAddress, amount: amount))
        } else {
            transaction.inputs
                .first { $0.previousOutpointAddress != walletAddress }
                .flatMap { .single(.init(address: $0.previousOutpointAddress, amount: amount)) }
        }
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

            let fee = transaction.inputs.map(\.previousOutpointAmount).reduce(0, +) - transaction.outputs.map(\.amount).reduce(0, +)

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
            ) else { return nil }

            return TransactionRecord(
                hash: transaction.hash,
                index: 0,
                source: source,
                destination: destination,
                fee: Fee(Amount(with: blockchain, value: Decimal(fee))),
                status: transaction.isAccepted ? .confirmed : .unconfirmed,
                isOutgoing: isOutgoing,
                type: .transfer,
                date: transaction.blockTime
            )
        }
    }
}
