//
//  WCTronSignTransactionDetailsModel.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

/// Request details for `tron_signTransaction`, built from the transaction decoded out of `raw_data_hex`
/// (`WalletConnectTronSignTransactionDTO.ParsedTransaction`) — the bytes that are actually signed.
struct WCTronSignTransactionDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data) {
        guard let parsed = try? JSONDecoder().decode(WalletConnectTronSignTransactionDTO.ParsedTransaction.self, from: source) else {
            data = []
            return
        }

        data = WCRequestDetailsTronSignTransactionParser.parse(transaction: parsed, method: method)
    }
}

enum WCRequestDetailsTronSignTransactionParser {
    private static let sunPerTrx: Decimal = 1_000_000

    static func parse(
        transaction: WalletConnectTronSignTransactionDTO.ParsedTransaction,
        method: WalletConnectMethod
    ) -> [WCTransactionDetailsSection] {
        [
            .init(
                sectionTitle: nil,
                items: [
                    .init(title: Localization.wcSignatureType, value: method.rawValue),
                    .init(title: "Contract", value: contractTypeName(transaction.kind)),
                ]
            ),
            makeTransactionSection(transaction),
        ]
    }

    private static func contractTypeName(_ kind: WalletConnectTronSignTransactionDTO.ParsedTransaction.Kind) -> String {
        switch kind {
        case .transfer: "TransferContract"
        case .contractCall: "TriggerSmartContract"
        }
    }

    private static func makeTransactionSection(_ transaction: WalletConnectTronSignTransactionDTO.ParsedTransaction) -> WCTransactionDetailsSection {
        var items: [WCTransactionDetailsSection.WCTransactionDetailsItem] = [
            .init(title: "From", value: transaction.ownerAddress),
        ]

        switch transaction.kind {
        case .transfer:
            items.append(.init(title: "To", value: transaction.targetAddress))
            items.append(.init(title: "Amount", value: formatTrx(sun: transaction.amountSun)))
        case .contractCall:
            items.append(.init(title: "Contract address", value: transaction.targetAddress))
            if transaction.amountSun > 0 {
                items.append(.init(title: "Call value", value: formatTrx(sun: transaction.amountSun)))
            }
            if let callData = transaction.callData, !callData.isEmpty {
                items.append(.init(title: "Data", value: "0x" + callData))
            }
            if let feeLimit = transaction.feeLimitSun {
                items.append(.init(title: "Fee limit", value: formatTrx(sun: feeLimit)))
            }
        }

        if let memo = transaction.memo, !memo.isEmpty {
            items.append(.init(title: "Memo", value: memo))
        }

        items.append(.init(title: "Transaction ID", value: transaction.txID))

        return .init(sectionTitle: "Transaction", items: items)
    }

    static func formatTrx(sun: Int64) -> String {
        let trx = Decimal(sun) / sunPerTrx
        return "\(trx) TRX"
    }
}
