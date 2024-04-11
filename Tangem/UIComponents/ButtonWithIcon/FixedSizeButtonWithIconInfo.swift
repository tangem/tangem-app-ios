//
//  FixedSizeButtonWithIconInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FixedSizeButtonWithIconInfo {
    let title: String
    let icon: ImageType
    let style: FixedSizeButtonWithLeadingIcon.Style
    let action: () -> Void
    var disabled: Bool

    init(title: String, icon: ImageType, disabled: Bool, style: FixedSizeButtonWithLeadingIcon.Style = .default, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.disabled = disabled
        self.action = action
    }

    /// Initializer with enabled button
    init(title: String, icon: ImageType, style: FixedSizeButtonWithLeadingIcon.Style = .default, action: @escaping () -> Void) {
        self.init(title: title, icon: icon, disabled: false, style: style, action: action)
    }
}

extension FixedSizeButtonWithIconInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(icon)
        hasher.combine(disabled)
    }

    static func == (lhs: FixedSizeButtonWithIconInfo, rhs: FixedSizeButtonWithIconInfo) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension FixedSizeButtonWithIconInfo: Identifiable {
    var id: Int { hashValue }
}
