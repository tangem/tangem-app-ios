//
//  UTXOTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemFoundation

struct UTXOTransactionHistoryMapper {
    private let blockchain: Blockchain
    private var decimalValue: Decimal {
        blockchain.decimalValue
    }

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

// MARK: - TransactionHistoryMapper protocol conformance

extension UTXOTransactionHistoryMapper: TransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: BlockBookAddressResponse,
        walletAddress: String,
        amountType: Amount.AmountType
    ) throws -> [TransactionRecord] {
        assert(amountType == .coin, "UTXOTransactionHistoryMapper doesn't support a token amount")

        guard let transactions = response.transactions else {
            return []
        }

        return try transactions.compactMap { transaction -> TransactionRecord? in
            try mapToTransactionRecord(transaction: transaction, walletAddress: walletAddress)
        }
    }

    func mapToTransactionRecord(transaction: BlockBookAddressResponse.Transaction, walletAddress: String) throws -> TransactionRecord {
        guard let feeSatoshi = Decimal(stringValue: transaction.fees) else {
            throw TransactionHistoryMapperError.notFound("Transaction.fees")
        }

        let isOutgoing = transaction.compat.vin.contains(where: { $0.addresses?.contains(walletAddress) == true })
        let status: TransactionRecord.TransactionStatus = transaction.confirmations > 0 ? .confirmed : .unconfirmed
        let fee = feeSatoshi / decimalValue

        return TransactionRecord(
            hash: transaction.txid,
            index: 0,
            source: sourceType(vin: transaction.compat.vin),
            destination: destinationType(vout: transaction.compat.vout),
            fee: Fee(Amount(with: blockchain, value: fee)),
            status: status,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: Date(timeIntervalSince1970: TimeInterval(transaction.blockTime))
        )
    }

    func sourceType(vin: [BlockBookAddressResponse.Vin]) -> TransactionRecord.SourceType {
        let spenders: [TransactionRecord.Source] = vin.reduce([]) { result, input in
            guard let value = input.value,
                  let amountSatoshi = Decimal(stringValue: value),
                  let address = input.addresses?.first else {
                return result
            }

            let amount = amountSatoshi / decimalValue
            return result + [TransactionRecord.Source(address: address, amount: amount)]
        }

        if let spender = spenders.singleElement {
            return .single(spender)
        }

        return .multiple(spenders)
    }

    func destinationType(vout: [BlockBookAddressResponse.Vout]) -> TransactionRecord.DestinationType {
        let destinations: [TransactionRecord.Destination] = vout.reduce([]) { result, output in
            guard let amountSatoshi = Decimal(stringValue: output.value),
                  let address = output.addresses?.first else {
                return result
            }

            let amount = amountSatoshi / decimalValue
            return result + [TransactionRecord.Destination(address: .user(address), amount: amount)]
        }

        if let destination = destinations.singleElement {
            return .single(destination)
        }

        return .multiple(destinations)
    }
}
