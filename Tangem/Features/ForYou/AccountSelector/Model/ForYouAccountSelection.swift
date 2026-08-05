//
//  ForYouAccountSelection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum ForYouAccountSelection: Equatable {
    case all
    case subset(Set<ForYouAccountID>)
}

/// Type-safe wrapper of the full `CryptoAccountModel.id` — unique across wallets.
struct ForYouAccountID: Hashable {
    private let raw: AnyHashable

    init(_ account: any CryptoAccountModel) {
        raw = account.id.toAnyHashable()
    }
}
