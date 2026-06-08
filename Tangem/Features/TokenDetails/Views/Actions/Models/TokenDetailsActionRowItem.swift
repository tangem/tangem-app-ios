//
//  TokenDetailsActionRowItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemFoundation

struct TokenDetailsActionRowItem: Identifiable, Equatable {
    let id: TokenActionType
    let title: String
    let subtitle: String?
    let icon: ImageType
    let accessibilityIdentifier: String?
    let isAvailable: Bool
    @IgnoredEquatable var action: () -> Void
}
