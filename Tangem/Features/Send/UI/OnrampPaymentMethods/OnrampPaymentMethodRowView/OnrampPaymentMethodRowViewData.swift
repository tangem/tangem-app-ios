//
//  OnrampPaymentMethodRowViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemUIUtils

struct OnrampPaymentMethodRowViewData: Identifiable {
    let id: String
    let name: String
    let iconURL: URL?

    let action: () -> Void
}

// MARK: - Hashable

extension OnrampPaymentMethodRowViewData: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(iconURL)
    }
}
