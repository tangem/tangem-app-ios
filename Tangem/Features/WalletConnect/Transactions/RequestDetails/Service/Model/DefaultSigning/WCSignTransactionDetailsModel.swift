//
//  WCSignTransactionDetailsMode.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct WCSignTransactionDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data) {
        let message = String(data: source, encoding: .utf8) ?? source.hexString

        data = [
            .init(
                sectionTitle: nil,
                items: [
                    .init(
                        title: Localization.wcSignatureType,
                        value: method.rawValue
                    ),
                    .init(
                        title: Localization.wcContents,
                        value: message
                    ),
                ]
            ),
        ]
    }
}
