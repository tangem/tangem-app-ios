//
//  TransactionDetailsProviderInfo.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct TransactionDetailsProviderInfo {
    let name: String
    /// Provider-type label (e.g. CEX / DEX / DEX/Bridge). `nil` for providers whose type isn't shown (e.g. onramp).
    let type: String?
    let onTap: (() -> Void)?

    var infoRow: TransactionDetailsInfoSectionViewData.Row {
        .init(
            id: "provider",
            title: Localization.expressProvider,
            content: .link(.init(text: name, secondaryText: type, handler: onTap))
        )
    }
}
