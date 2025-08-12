//
//  WCSolanaSignAllTransactionsDetailsModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct WCSolanaSignAllTransactionsDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data) {
        guard
            let items = try? JSONDecoder().decode([String].self, from: source)
        else {
            data = []
            return
        }

        let transactionItems = items.map {
            WCTransactionDetailsSection.WCTransactionDetailsItem(title: "Transaction", value: $0)
        }

        data = [
            .init(
                sectionTitle: nil,
                items: { () -> [WCTransactionDetailsSection.WCTransactionDetailsItem] in
                    [.init(title: Localization.wcSignatureType, value: method.rawValue)] + transactionItems
                }()
            ),
        ]
    }
}
