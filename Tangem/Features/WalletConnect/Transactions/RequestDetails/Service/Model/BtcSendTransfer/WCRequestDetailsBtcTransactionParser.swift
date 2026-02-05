//
//  WCRequestDetailsBtcTransactionParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum WCRequestDetailsBtcTransactionParser {
    static func parse(
        transaction: WalletConnectBtcTransaction,
        method: WalletConnectMethod,
        blockchain: Blockchain
    ) -> [WCTransactionDetailsSection] {
        [
            createTransactionTypeSection(method: method),
            createTransactionSection(transaction: transaction, blockchain: blockchain),
        ]
    }

    private static func createTransactionTypeSection(method: WalletConnectMethod) -> WCTransactionDetailsSection {
        .init(
            sectionTitle: nil,
            items: [.init(title: "Transaction Type", value: method.rawValue)]
        )
    }

    private static func createTransactionSection(
        transaction: WalletConnectBtcTransaction,
        blockchain: Blockchain
    ) -> WCTransactionDetailsSection {
        var items: [WCTransactionDetailsSection.WCTransactionDetailsItem] = [
            .init(title: "From", value: transaction.account),
            .init(title: "To", value: transaction.recipientAddress),
            .init(title: "Amount", value: formatAmount(transaction.amount, blockchain: blockchain)),
        ]

        if let changeAddress = transaction.changeAddress, changeAddress.isNotEmpty {
            items.append(.init(title: "Change Address", value: changeAddress))
        }

        return .init(sectionTitle: "Transaction", items: items)
    }

    private static func formatAmount(_ amount: String, blockchain: Blockchain) -> String {
        guard let amountDecimal = Decimal(string: amount) else {
            return amount
        }

        let coinAmount = amountDecimal / blockchain.decimalValue
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 8

        let formattedValue = formatter.string(from: coinAmount as NSDecimalNumber) ?? "\(coinAmount)"
        return "\(formattedValue) \(blockchain.currencySymbol)"
    }
}
