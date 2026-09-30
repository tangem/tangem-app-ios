//
//  WCHederaTransactionDetailsModel.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

/// Request details for `hedera_signAndExecuteTransaction` / `hedera_signTransaction`, built from the transaction
/// the Hiero SDK decoded out of the dApp's bytes (`WalletConnectHederaTransactionDetails`).
struct WCHederaTransactionDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data) {
        guard let details = try? JSONDecoder().decode(WalletConnectHederaTransactionDetails.self, from: source) else {
            data = []
            return
        }

        data = WCRequestDetailsHederaTransactionParser.parse(details: details, method: method)
    }
}

enum WCRequestDetailsHederaTransactionParser {
    private static let tinybarsPerHbar: Decimal = 100_000_000

    static func parse(details: WalletConnectHederaTransactionDetails, method: WalletConnectMethod) -> [WCTransactionDetailsSection] {
        var sections: [WCTransactionDetailsSection] = [
            .init(
                sectionTitle: nil,
                items: [
                    .init(title: Localization.wcSignatureType, value: method.rawValue),
                    .init(title: "Transaction", value: details.transactionType),
                ]
            ),
            makeTransactionSection(details),
        ]

        if !details.hbarTransfers.isEmpty {
            sections.append(.init(
                sectionTitle: "HBAR transfers",
                items: details.hbarTransfers.map { .init(title: $0.account, value: formatHbar(tinybars: $0.amount, signed: true)) }
            ))
        }

        if !details.tokenTransfers.isEmpty {
            sections.append(.init(
                sectionTitle: "Token transfers",
                items: details.tokenTransfers.map { .init(title: "\($0.tokenId ?? "") → \($0.account)", value: String($0.amount)) }
            ))
        }

        return sections
    }

    private static func makeTransactionSection(_ details: WalletConnectHederaTransactionDetails) -> WCTransactionDetailsSection {
        var items: [WCTransactionDetailsSection.WCTransactionDetailsItem] = []

        if let payer = details.payerAccountId {
            items.append(.init(title: "Payer", value: payer))
        }
        if let transactionId = details.transactionId {
            items.append(.init(title: "Transaction ID", value: transactionId))
        }
        if !details.nodeAccountIds.isEmpty {
            items.append(.init(title: "Nodes", value: details.nodeAccountIds.joined(separator: ", ")))
        }
        if let maxFee = details.maxFeeTinybars {
            items.append(.init(title: "Max fee", value: formatHbar(tinybars: maxFee, signed: false)))
        }
        if !details.memo.isEmpty {
            items.append(.init(title: "Memo", value: details.memo))
        }

        return .init(sectionTitle: "Transaction", items: items)
    }

    static func formatHbar(tinybars: Int64, signed: Bool) -> String {
        let hbar = Decimal(tinybars) / tinybarsPerHbar
        let prefix = signed && tinybars > 0 ? "+" : ""
        return "\(prefix)\(hbar) HBAR"
    }
}
