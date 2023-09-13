//
//  LegacyTransactionMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct LegacyTransactionMapper {
    private let formatter = BalanceFormatter()

    func mapToIncomingRecords(_ transactions: [Transaction]) -> [LegacyTransactionRecord] {
        transactions.map {
            mapToPendingLegacyTransactionRecord($0, type: .receive)
        }
    }

    func mapToOutgoingRecords(_ transactions: [Transaction]) -> [LegacyTransactionRecord] {
        transactions.map {
            mapToPendingLegacyTransactionRecord($0, type: .send)
        }
    }
}

private extension LegacyTransactionMapper {
    func mapToPendingLegacyTransactionRecord(
        _ transaction: Transaction,
        type: LegacyTransactionRecord.TransactionType
    ) -> LegacyTransactionRecord {
        LegacyTransactionRecord(
            amountType: transaction.amount.type,
            destination: transaction.destinationAddress,
            timeFormatted: "",
            transferAmount: transferAmount(for: transaction),
            transactionType: type,
            status: .inProgress
        )
    }

    func transferAmount(for transaction: Transaction) -> String {
        guard transaction.amount.value > 0 else {
            return transaction.amount.currencySymbol
        }

        return formatter.formatCryptoBalance(
            transaction.amount.value,
            currencyCode: transaction.amount.currencySymbol
        )
    }
}
