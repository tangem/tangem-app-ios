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
    var disabled: Bool

    init(title: String, icon: ImageType, action: @escaping () -> Void, disabled: Bool) {
        self.title = title
        self.icon = icon
        self.action = action
        self.disabled = disabled
    }

    /// Initializer with enabled button
    init(title: String, icon: ImageType, action: @escaping () -> Void) {
        self.init(title: title, icon: icon, action: action, disabled: false)
    }
}

extension ButtonWithIconInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(icon)
        hasher.combine(disabled)
    }

    static func == (lhs: ButtonWithIconInfo, rhs: ButtonWithIconInfo) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension ButtonWithIconInfo: Identifiable {
    var id: Int { hashValue }
}
