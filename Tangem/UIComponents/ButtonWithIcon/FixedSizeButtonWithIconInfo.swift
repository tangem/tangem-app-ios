//
//  FixedSizeButtonWithIconInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FixedSizeButtonWithIconInfo {
    typealias ButtonAction = () -> Void
    let title: String
    let icon: ImageType
    let style: FixedSizeButtonWithLeadingIcon.Style
    let shouldShowBadge: Bool
    let action: ButtonAction
    let longPressAction: ButtonAction?
    let disabled: Bool

    init(
        title: String,
        icon: ImageType,
        disabled: Bool,
        style: FixedSizeButtonWithLeadingIcon.Style = .default,
        shouldShowBadge: Bool = false,
        action: @escaping ButtonAction,
        longPressAction: ButtonAction? = nil
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.shouldShowBadge = shouldShowBadge
        self.disabled = disabled
        self.action = action
        self.longPressAction = longPressAction
    }

    /// Initializer with enabled button
    init(title: String, icon: ImageType, style: FixedSizeButtonWithLeadingIcon.Style = .default, action: @escaping ButtonAction, longPressAction: ButtonAction? = nil) {
        self.init(title: title, icon: icon, disabled: false, style: style, action: action, longPressAction: longPressAction)
    }
}

extension FixedSizeButtonWithIconInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(icon)
        hasher.combine(disabled)
        hasher.combine(shouldShowBadge)
        hasher.combine(style)
    }

    static func == (lhs: FixedSizeButtonWithIconInfo, rhs: FixedSizeButtonWithIconInfo) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension FixedSizeButtonWithIconInfo: Identifiable {
    var id: Int { hashValue }
}
