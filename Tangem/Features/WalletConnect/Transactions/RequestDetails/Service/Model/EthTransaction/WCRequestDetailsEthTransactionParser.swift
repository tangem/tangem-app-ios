//
//  WCRequestDetailsEthTransactionParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Parser for Ethereum transaction details
enum WCRequestDetailsEthTransactionParser {
    // MARK: - Public Methods

    static func parse(transaction: WalletConnectEthTransaction, method: WalletConnectMethod) -> [WCTransactionDetailsSection] {
        var sections: [WCTransactionDetailsSection] = []

        sections.append(createTransactionTypeSection(method: method))

        sections.append(createBasicDetailsSection(transaction: transaction))

        if let advancedSection = createAdvancedDetailsSection(transaction: transaction) {
            sections.append(advancedSection)
        }

        return sections
    }

    // MARK: - Section Creators

    private static func createTransactionTypeSection(method: WalletConnectMethod) -> WCTransactionDetailsSection {
        return .init(
            sectionTitle: nil,
            items: [.init(title: "Transaction Type", value: method.rawValue)]
        )
    }

    private static func createBasicDetailsSection(transaction: WalletConnectEthTransaction) -> WCTransactionDetailsSection {
        let basicItems: [WCTransactionDetailsSection.WCTransactionDetailsItem] = [
            .init(title: "From", value: transaction.from),
            .init(title: "To", value: transaction.to),
            .init(title: "Value", value: formatEthValue(transaction.value ?? "0x0")),
        ]

        return .init(sectionTitle: "Transaction", items: basicItems)
    }

    private static func createAdvancedDetailsSection(transaction: WalletConnectEthTransaction) -> WCTransactionDetailsSection? {
        var advancedItems: [WCTransactionDetailsSection.WCTransactionDetailsItem] = []

        if !transaction.data.isEmpty, transaction.data != "0x" {
            advancedItems.append(.init(title: "Data", value: formatData(transaction.data)))
        }

        if let gasPrice = transaction.gasPrice {
            advancedItems.append(.init(title: "Gas Price", value: formatGasPrice(gasPrice)))
        }

        let gasLimit = transaction.gasLimit ?? transaction.gas
        if let gasLimit = gasLimit {
            advancedItems.append(.init(title: "Gas Limit", value: formatGas(gasLimit)))
        }

        if let nonce = transaction.nonce {
            advancedItems.append(.init(title: "Nonce", value: formatNonce(nonce)))
        }

        if advancedItems.isEmpty {
            return nil
        }

        return .init(sectionTitle: "Advanced", items: advancedItems)
    }

    // MARK: - Value Formatters

    private static func formatEthValue(_ hexValue: String) -> String {
        guard let value = Int(hexValue.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            return hexValue
        }

        // Convert to ETH units (wei to ETH)
        let ethValue = Decimal(value) / pow(10, 18)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8

        let formattedValue = formatter.string(from: ethValue as NSDecimalNumber) ?? "\(ethValue)"
        return "\(formattedValue) ETH"
    }

    private static func formatGasPrice(_ hexGasPrice: String) -> String {
        guard let gasPrice = Int(hexGasPrice.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            return hexGasPrice
        }

        // Convert to Gwei units
        let gweiValue = Decimal(gasPrice) / pow(10, 9)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2

        let formattedValue = formatter.string(from: gweiValue as NSDecimalNumber) ?? "\(gweiValue)"
        return "\(formattedValue) Gwei"
    }

    private static func formatGas(_ hexGas: String) -> String {
        guard let gas = Int(hexGas.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            return hexGas
        }

        return "\(gas)"
    }

    private static func formatNonce(_ hexNonce: String) -> String {
        guard let nonce = Int(hexNonce.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            return hexNonce
        }

        return "\(nonce)"
    }

    private static func formatData(_ data: String) -> String {
        if data.count > 66 {
            return "\(data.prefix(8))...\(data.suffix(8))"
        }
        return data
    }
}
