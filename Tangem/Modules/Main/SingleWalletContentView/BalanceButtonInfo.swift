//
//  BalanceButtonInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceButtonInfo {
    let title: String
    let icon: ImageType
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
}

extension BalanceButtonInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(icon)
        hasher.combine(isLoading)
        hasher.combine(isDisabled)
    }

    static func == (lhs: BalanceButtonInfo, rhs: BalanceButtonInfo) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension BalanceButtonInfo: Identifiable {
    var id: Int { hashValue }
}
