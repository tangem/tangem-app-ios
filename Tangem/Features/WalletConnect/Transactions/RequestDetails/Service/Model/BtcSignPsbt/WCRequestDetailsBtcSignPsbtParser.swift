//
//  WCRequestDetailsBtcSignPsbtParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum WCRequestDetailsBtcSignPsbtParser {
    static func parse(
        request: WalletConnectBitcoinSignPsbtDTO.Request,
        method: WalletConnectMethod
    ) -> [WCTransactionDetailsSection] {
        [
            createTransactionTypeSection(method: method),
            createRequestSection(request: request),
            createSignInputsSection(signInputs: request.signInputs),
        ]
    }

    private static func createTransactionTypeSection(method: WalletConnectMethod) -> WCTransactionDetailsSection {
        .init(
            sectionTitle: nil,
            items: [.init(title: "Transaction Type", value: method.rawValue)]
        )
    }

    private static func createRequestSection(request: WalletConnectBitcoinSignPsbtDTO.Request) -> WCTransactionDetailsSection {
        var items: [WCTransactionDetailsSection.WCTransactionDetailsItem] = [
            .init(title: "PSBT", value: request.psbt),
        ]

        if let broadcast = request.broadcast {
            items.append(.init(title: "Broadcast", value: String(broadcast)))
        }

        return .init(sectionTitle: "Request", items: items)
    }

    private static func createSignInputsSection(signInputs: [WalletConnectPsbtSignInput]) -> WCTransactionDetailsSection {
        let items: [WCTransactionDetailsSection.WCTransactionDetailsItem]

        if signInputs.isEmpty {
            items = [.init(title: "Sign inputs", value: "None")]
        } else {
            items = signInputs
                .sorted { $0.index < $1.index }
                .map { signInput in
                    .init(
                        title: "Input \(signInput.index)",
                        value: formatSignInput(signInput)
                    )
                }
        }

        return .init(sectionTitle: "Sign inputs", items: items)
    }

    private static func formatSignInput(_ signInput: WalletConnectPsbtSignInput) -> String {
        [
            "Address: \(signInput.address)",
            "Sighash types: \(formatSighashTypes(signInput.sighashTypes))",
        ].joined(separator: "\n")
    }

    private static func formatSighashTypes(_ sighashTypes: [Int]?) -> String {
        guard let sighashTypes, sighashTypes.isNotEmpty else {
            return "Not specified"
        }

        return sighashTypes
            .map(String.init)
            .joined(separator: ", ")
    }
}
