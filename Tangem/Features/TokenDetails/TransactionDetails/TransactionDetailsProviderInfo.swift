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
    let iconURL: URL?
    let onTap: () -> Void

    var infoRow: TransactionDetailsInfoSectionViewData.Row {
        .init(
            id: "provider",
            title: Localization.expressProvider,
            content: .link(.init(text: name, iconURL: iconURL, handler: onTap))
        )
    }
}
