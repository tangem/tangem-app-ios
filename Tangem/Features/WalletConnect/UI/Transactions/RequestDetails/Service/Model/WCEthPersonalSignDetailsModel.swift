//
//  WCEthPersonalSignDetailsModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCEthPersonalSignDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data) {
        let message = String(data: source, encoding: .utf8) ?? source.hexString

        data = [
            .init(
                sectionTitle: nil,
                items: [
                    .init(
                        title: "Signature Type",
                        value: method.rawValue
                    ),
                    .init(
                        title: "Contents",
                        value: message
                    ),
                ]
            ),
        ]
    }
}
