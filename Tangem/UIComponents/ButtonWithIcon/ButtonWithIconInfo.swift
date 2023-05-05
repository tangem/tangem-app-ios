//
//  TotalBalanceButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ButtonWithIconInfo {
    let title: String
    let icon: ImageType
    let action: () -> Void
}

extension ButtonWithIconInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(icon)
    }

    static func == (lhs: ButtonWithIconInfo, rhs: ButtonWithIconInfo) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension ButtonWithIconInfo: Identifiable {
    var id: Int { hashValue }
}
