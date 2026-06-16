//
//  WCRequestDetailsBtcGetAccountAddressesParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum WCRequestDetailsBtcGetAccountAddressesParser {
    static func parse(
        request: WalletConnectBtcGetAccountAddressesRequest,
        method: WalletConnectMethod
    ) -> [WCTransactionDetailsSection] {
        [
            createTransactionTypeSection(method: method),
            createRequestSection(request: request),
        ]
    }

    private static func createTransactionTypeSection(method: WalletConnectMethod) -> WCTransactionDetailsSection {
        .init(
            sectionTitle: nil,
            items: [.init(title: "Transaction Type", value: method.rawValue)]
        )
    }

    private static func createRequestSection(request: WalletConnectBtcGetAccountAddressesRequest) -> WCTransactionDetailsSection {
        .init(
            sectionTitle: "Request",
            items: [.init(title: "Intentions", value: formatIntentions(request.intentions))]
        )
    }

    private static func formatIntentions(_ intentions: [String]?) -> String {
        guard let intentions, intentions.isNotEmpty else {
            return "Not specified"
        }

        return intentions.joined(separator: ", ")
    }
}
