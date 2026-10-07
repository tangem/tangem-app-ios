//
//  TransactionHistoryGaslessFeeAttacher.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

/// Moves the fee the relayer charged for a gasless transaction into the row of the operation it paid for.
struct TransactionHistoryGaslessFeeAttacher {
    private let currentToken: TokenItem

    init(currentToken: TokenItem) {
        self.currentToken = currentToken
    }

    func replacingRelayerGas(
        in records: [TransactionRecord],
        matchedBy feeMatcher: GaslessTransactionFeeMatcher,
        auxDataRepository: TransactionHistoryAuxDataRepository
    ) -> [TransactionRecord] {
        records.map { record in
            fee(paidWith: feeMatcher.feeTokenTransfers(of: record), auxDataRepository: auxDataRepository)
                .map(record.withFee) ?? record
        }
    }

    func attach(_ gaslessFees: [TransactionRecord], to rows: [TransactionRecord]) -> [TransactionRecord] {
        guard gaslessFees.isNotEmpty else {
            return rows
        }

        let payingRowIndices = payingRowIndices(in: rows)
        var rows = rows
        var unattachedFees: [TransactionRecord] = []

        for (hash, fees) in gaslessFees.grouped(by: \.hash) {
            guard let rowIndex = payingRowIndices[hash] else {
                unattachedFees.append(contentsOf: fees)
                continue
            }

            let paid = fees.reduce(Decimal.zero) { $0 + $1.destinationAmountValue }
            let fee = Fee(Amount(with: currentToken.blockchain, type: currentToken.amountType, value: paid))
            rows[rowIndex] = rows[rowIndex].withFee(fee)
        }

        return rows + unattachedFees
    }

    private func fee(
        paidWith transfers: [TransactionRecord.TokenTransfer],
        auxDataRepository: TransactionHistoryAuxDataRepository
    ) -> Fee? {
        // All transfers here already go to a collector; if they are in different tokens, there is no single fee to show
        guard
            let transfer = transfers.first,
            let contract = transfer.contract,
            transfers.allSatisfy({ $0.contract?.caseInsensitiveEquals(to: contract) == true })
        else {
            return nil
        }

        let rawAmount = transfers.reduce(Decimal.zero) { $0 + $1.amount }

        if let tokenItem = auxDataRepository.cryptoCurrency(forContract: contract, blockchain: currentToken.blockchain) {
            let value = rawAmount / pow(Decimal(10), tokenItem.decimalCount)
            return Fee(Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value))
        }

        guard let symbol = transfer.symbol, let decimals = transfer.decimals else {
            return nil
        }

        let token = Token(name: transfer.name ?? symbol, symbol: symbol, contractAddress: contract, decimalCount: decimals)
        return Fee(Amount(with: token, value: rawAmount / pow(Decimal(10), decimals)))
    }

    private func payingRowIndices(in rows: [TransactionRecord]) -> [String: Int] {
        var firstRowIndices: [String: Int] = [:]
        var firstOutgoingRowIndices: [String: Int] = [:]

        for (index, row) in rows.enumerated() {
            if firstRowIndices[row.hash] == nil {
                firstRowIndices[row.hash] = index
            }

            if row.isOutgoing, firstOutgoingRowIndices[row.hash] == nil {
                firstOutgoingRowIndices[row.hash] = index
            }
        }

        return firstRowIndices.merging(firstOutgoingRowIndices) { $1 }
    }
}

// MARK: - Private

private extension TransactionRecord {
    func withFee(_ fee: Fee) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: index,
            source: source,
            destination: destination,
            fee: fee,
            status: status,
            isOutgoing: isOutgoing,
            type: type,
            date: date,
            tokenTransfers: tokenTransfers,
            isFromYieldContract: isFromYieldContract,
            isFolded: isFolded,
            nonce: nonce,
            extraInfo: expressExtraInfo
        )
    }
}
